import net.http
import json
import os
import time

// --- Data Models ---

struct Part {
pub mut:
	text              ?string           @[json: 'text'; optional]
	thought_signature ?string           @[json: 'thoughtSignature'; optional]
	function_call     ?FunctionCall     @[json: 'functionCall'; optional]
	function_response ?FunctionResponse @[json: 'functionResponse'; optional]
}

struct FunctionCall {
pub:
	name string @[json: 'name']
	args map[string]string @[json: 'args']
}

struct FunctionResponse {
pub:
	name     string @[json: 'name']
	response map[string]string @[json: 'response']
}

struct Content {
pub mut:
	role  string @[json: 'role']
	parts []Part @[json: 'parts']
}

struct Tool {
pub:
	function_declarations []FunctionDeclaration @[json: 'function_declarations']
}

struct FunctionDeclaration {
pub:
	name        string @[json: 'name']
	description string @[json: 'description']
	parameters  Schema @[json: 'parameters']
}

struct Schema {
pub:
	type_       string            @[json: 'type']
	properties  map[string]Property @[json: 'properties']
	required    []string          @[json: 'required']
}

struct Property {
pub:
	type_       string @[json: 'type']
	description string @[json: 'description']
}

struct GenerateRequest {
pub:
	contents           []Content           @[json: 'contents']
	tools              []Tool              @[json: 'tools'; optional]
	system_instruction ?Content            @[json: 'system_instruction'; optional]
}

struct GenerateResponse {
pub:
	candidates []Candidate @[json: 'candidates']
}

struct Candidate {
pub:
	content Content @[json: 'content']
}

@[heap]
struct AppContext {
mut:
	buffer     string
	full_resp  string
	out       os.File
	last_parts []Part
	interactive bool = true
}

fn stream_callback(request &http.Request, chunk []u8, read_so_far u64, expected_size u64, status_code int) ! {
	mut ctx := unsafe { &AppContext(request.user_ptr) }
	ctx.buffer += chunk.bytestr()

	for {
		start_idx := ctx.buffer.index('data: ') or { break }
		mut end_idx := ctx.buffer.index_after('data: ', start_idx + 6) or { -1 }
		if end_idx == -1 {
			if ctx.buffer.ends_with('\n\n') || ctx.buffer.len > 10000 {
				end_idx = ctx.buffer.len
			} else {
				break 
			}
		}

		raw_chunk := ctx.buffer[start_idx..end_idx].trim_space()
		ctx.buffer = ctx.buffer[end_idx..]

		if raw_chunk.starts_with('data: ') {
			json_str := raw_chunk[6..].trim_space()
			if json_str == '' || json_str == '[DONE]' { continue }
			
			resp := json.decode(GenerateResponse, json_str) or { continue }

			if resp.candidates.len > 0 {
				cand := resp.candidates[0]
				for part in cand.content.parts {
					ctx.last_parts << part
					if t := part.text {
						if t != '' {
							print(t)
							ctx.out.flush()
							ctx.full_resp += t
						}
					}
				}
			}
		}
	}
}

fn do_request_with_retry(api_url string, proxy_url string, body string, mut ctx AppContext) !http.Response {
	mut last_err := error('unknown error')
	for attempt in 1 .. 4 {
		mut req := http.Request{
			url: api_url
			method: .post
			data: body
			user_ptr: voidptr(ctx)
			on_progress_body: stream_callback
			stop_copying_limit: 0
			validate: false
			read_timeout: 60 * time.second
		}
		if proxy_url != '' { req.proxy = http.new_http_proxy(proxy_url) or { unsafe { nil } } }
		req.add_header(.content_type, 'application/json')
		req.add_header(.accept, 'text/event-stream')
		req.add_header(.connection, 'close')

		res := req.do() or {
			last_err = err
			if err.msg().contains('HTTP/') {
				if ctx.interactive { println('\n[Network] Proxy retry $attempt') }
				time.sleep(500 * time.millisecond)
				continue
			}
			return err
		}
		return res
	}
	return last_err
}

fn do_gemini_request(api_url string, proxy_url string, mut history []Content, mut ctx AppContext) ! {
	tools := [
		Tool{
			function_declarations: [
				FunctionDeclaration{
					name: 'list_directory'
					description: 'List files and directories in a given path'
					parameters: Schema{ type_: 'object', properties: {'path': Property{'string', 'The directory path to list'}}, required: ['path'] }
				},
				FunctionDeclaration{
					name: 'read_file'
					description: 'Read the content of a file'
					parameters: Schema{ type_: 'object', properties: {'path': Property{'string', 'The path of the file to read'}}, required: ['path'] }
				},
				FunctionDeclaration{
					name: 'write_file'
					description: 'Write content to a file'
					parameters: Schema{ 
						type_: 'object' 
						properties: {
							'path': Property{'string', 'The path to write to'},
							'content': Property{'string', 'The content to write'}
						}
						required: ['path', 'content'] 
					}
				},
				FunctionDeclaration{
					name: 'run_command'
					description: 'Execute a shell command'
					parameters: Schema{ type_: 'object', properties: {'command': Property{'string', 'The command to run'}}, required: ['command'] }
				}
			]
		}
	]

	for {
		ctx.full_resp = ''
		ctx.buffer = ''
		ctx.last_parts = []

		req_body := json.encode(GenerateRequest{
			contents: history
			tools: tools
			system_instruction: Content{
				role: 'system'
				parts: [Part{text: 'You are a helpful Vlang Agent with access to the local file system and shell. Use tools to help the user with their requests.'}]
			}
		})

		res := do_request_with_retry(api_url, proxy_url, req_body, mut ctx)!
		if res.status_code != 200 {
			return error('API Error (Status ${res.status_code}): ${res.body}')
		}

		mut has_fc := false
		for p in ctx.last_parts {
			if _ := p.function_call {
				has_fc = true
				break
			}
		}

		if has_fc {
			history << Content{ role: 'model', parts: ctx.last_parts }

			mut response_parts := []Part{}
			for p in ctx.last_parts {
				if fc := p.function_call {
					result := match fc.name {
						'list_directory' {
							p_dir := fc.args['path'] or { '.' }
							os.ls(p_dir) or { ['Error: Could not list directory'] }.join('\n')
						}
						'read_file' {
							p_file := fc.args['path'] or { '' }
							os.read_file(p_file) or { 'Error: Could not read file' }
						}
						'write_file' {
							p_dest := fc.args['path'] or { '' }
							content := fc.args['content'] or { '' }
							os.write_file(p_dest, content) or { 'Error: Could not write file' }
							'Successfully wrote to ${p_dest}'
						}
						'run_command' {
							cmd := fc.args['command'] or { '' }
							os.execute(cmd).output
						}
						else { 'Tool not found' }
					}
					if ctx.interactive { println('\n[Action] Executed ${fc.name}') }
					
					response_parts << Part{
						text: none
						function_response: FunctionResponse{ name: fc.name, response: { 'content': result } }
					}
				}
			}

			history << Content{ role: 'function', parts: response_parts }
			if ctx.interactive { println('Thinking...\n') }
			continue
		} else {
			if ctx.full_resp != '' {
				history << Content{ role: 'model', parts: [Part{text: ctx.full_resp}] }
			}
			break
		}
	}
}

fn main() {
	api_key := os.getenv('GEMINI_API_KEY')
	if api_key == '' { exit(1) }
	mut proxy_url := os.getenv('HTTPS_PROXY')
	if proxy_url == '' { proxy_url = os.getenv('http_proxy') }
	
	model := 'gemini-3-flash-preview'
	api_url := 'https://generativelanguage.googleapis.com/v1beta/models/${model}:streamGenerateContent?alt=sse&key=${api_key}'

	mut history := []Content{}
	mut ctx := &AppContext{ out: os.stdout() }

	args := os.args
	mut prompt := ''
	for i := 0; i < args.len; i++ {
		if args[i] in ['-p', '--prompt'] {
			if i + 1 < args.len {
				prompt = args[i+1]
				ctx.interactive = false
				i++
			}
		}
	}

	if !ctx.interactive {
		history << Content{ role: 'user', parts: [Part{ text: prompt }] }
		do_gemini_request(api_url, proxy_url, mut history, mut ctx) or {
			eprintln('\nAgent Error: $err')
			exit(1)
		}
		println('')
		return
	}

	println('--- Gemini V-Agent (Extended Tools Mode) ---')
	for {
		print('\nYou > ')
		ctx.out.flush()
		input := os.get_line().trim_space()
		if input in ['exit', 'quit'] { break }
		if input == '' { continue }
		history << Content{ role: 'user', parts: [Part{ text: input }] }
		print('Gemini > ')
		ctx.out.flush()
		do_gemini_request(api_url, proxy_url, mut history, mut ctx) or {
			eprintln('\nAgent Error: $err')
		}
		println('')
	}
}