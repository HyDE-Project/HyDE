import Service from "resource:///com/github/Aylur/ags/service.js";
import Gio from "gi://Gio";
import GLib from "gi://GLib";
// @ts-ignore
import Soup from "gi://Soup?version=3.0";
import Keys from "../../keys.js";

Gio._promisify(Gio.DataInputStream.prototype, "read_upto_async");

export class CodyAIMessage extends Service {
  static {
    Service.register(this, {},
      {
        "content": ["string"],
        "thinking": ["boolean"]
      });
  }

  _role = "";
  _content = "";
  _thinking = false;

  /**
   * @param {string} role
   * @param {string} content
   * @param {boolean} [thinking=false]
   * @constructor
   */
  constructor(role, content, thinking = false) {
    super();
    this._role = role;
    this._content = content;
    this._thinking = thinking;
  }

  get role() {
    return this._role;
  }

  set role(role) {
    this._role = role;
    this.emit("changed");
  }

  get content() {
    return this._content;
  }

  set content(content) {
    this._content = content;
    this.notify("content");
    this.emit("changed");
  }

  get thinking() {
    return this._thinking;
  }

  set thinking(thinking) {
    this._thinking = thinking;
    this.notify("thinking");
    this.emit("changed");
  }

  /**
   * @param {string} delta
  */
  addDelta(delta) {
    if (this.thinking) {
      this.thinking = false;
      this.content = delta;
    } else {
      this.content += delta;
    }
  }
}

class CodyAIService extends Service {
  static {
    Service.register(this, {
      "newMsg": ["int"],
      "clear": [],
    }, {
      "temperature": ["double", "rw"],
      "model": ["string", "rw"],
      "system-message": ["string", "rw"]
    });
  }

  _systemMessage = {
    role: "system",
    content: ""
  };

  /** @type {CodyAIMessage[]} */
  _messages = [];
  _decoder = new TextDecoder();
  _model = "cody-v1";
  _temperature = 1;
  url = GLib.Uri.parse("https://api.sourcegraph.com/cody/v1/chat", GLib.UriFlags.NONE);

  constructor(){
    super();
    if(!Keys.SOURCEGRAPH_API_KEY) {
      console.error("CodyAI: API Key is not set!");
    }
  }

  getModels(){
    return [
      "cody-v1",
      "cody-v2"
    ];
  }

  set systemMessage(msg) {
    this._systemMessage.content = msg;
    this.notify("system-message");
  }

  get systemMessage() {
    return this._systemMessage.content;
  }

  set temperature(temp) {
    if(temp < 0 || temp > 2){
      console.warn("temperature must be between 0 and 2");
      return;
    }
    this._temperature = temp;
    this.notify("temperature");
  }

  get temperature() {
    return this._temperature;
  }

  set model(model) {
    if(!this.getModels().includes(model)){
      console.warn("model must be one of " + this.getModels());
      return;
    }
    this._model = model;
    this.notify("model");
  }

  get model(){
    return this._model;
  }

  get messages() {
    return this._messages;
  }

  get lastMessage() {
    return this.messages[this.messages.length - 1];
  }

  clear() {
    this._messages = [];
    this.emit("clear");
  }

  /**
   * @param {Gio.DataInputStream} stream
   * @param {CodyAIMessage} aiResponse
  */
  readResponse(stream, aiResponse) {
    stream.read_line_async(
      0, null,
      (stream, res) => {
        if (!stream) {
          return;
        }
        const [bytes] = stream.read_line_finish(res);
        const line = this._decoder.decode(bytes ?? undefined);
        if (line && line != "") {
          let data = line.substring(6);
          if (data == "[DONE]") return;
          try {
            const result = JSON.parse(data);
            if (result.choices[0].finish_reason === "stop") return;
            aiResponse.addDelta(result.choices[0].delta.content);
          } catch {
            aiResponse.addDelta(line + "\n");
          }
        }
        this.readResponse(stream, aiResponse);
      });
  }

  /**
   * @param {Gio.DataInputStream} stream
   * @param {CodyAIMessage} aiResponse
  */
  async showError(stream, aiResponse) {
    if (!stream) {
      return;
    }
    const [data] = await stream.read_upto_async("\x04", -1, 0, null);
    if (data) {
      aiResponse.addDelta("```json\n");
      aiResponse.addDelta(data);
      aiResponse.addDelta("\n```");
    }
  }

  /** @param {string} msg } */
  send(msg) {
    this.messages.push(new CodyAIMessage("user", msg));
    this.emit("newMsg", this.messages.length - 1);

    const messages = this.messages.map(msg => {
      let m = {role: msg.role, content: msg.content};
      return m;
    });

    const aiResponse = new CodyAIMessage("assistant", "thinking...", true);
    this.messages.push(aiResponse);
    this.emit("newMsg", this.messages.length - 1);

    const body = {
      model: this._model,
      temperature: this._temperature,
      messages: this._systemMessage.content != "" ? [this._systemMessage, ...messages] : messages,
      stream: true,
    };

    const session = new Soup.Session();
    const message = new Soup.Message({
      method: "POST",
      uri: this.url,
    });
    message.request_headers.append("Authorization", "Bearer " + Keys.SOURCEGRAPH_API_KEY);
    // @ts-ignore
    message.set_request_body_from_bytes("application/json", new GLib.Bytes(JSON.stringify(body)));
    session.send_async(message, 0, null, /** @type Gio.AsyncReadyCallback*/(_, result) => {
      const stream = session.send_finish(result);
      const dataStream = new Gio.DataInputStream({
        close_base_stream: true,
        base_stream: stream
      });
      if(message.get_status() == 200) this.readResponse(dataStream, aiResponse);
      else this.showError(dataStream, aiResponse);
    });
  }
}

export default new CodyAIService();
