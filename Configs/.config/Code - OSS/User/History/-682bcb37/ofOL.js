import Service from "resource:///com/github/Aylur/ags/service.js";
import Gio from "gi://Gio";
import GLib from "gi://GLib";
import Soup from "gi://Soup?version=3.0";
import Keys from "../../keys.js";

Gio._promisify(Gio.DataInputStream.prototype, "read_upto_async");

export class CodyMessage extends Service {
  static {
    Service.register(this, {}, {
      "content": ["string"],
      "thinking": ["boolean"]
    });
  }

  _role = "";
  _content = "";
  _thinking = false;

  constructor(role, content, thinking = false) {
    super();
    this._role = role;
    this._content = content;
    this._thinking = thinking;
  }

  get role() { return this._role; }
  set role(role) {
    this._role = role;
    this.emit("changed");
  }

  get content() { return this._content; }
  set content(content) {
    this._content = content;
    this.notify("content");
    this.emit("changed");
  }

  get thinking() { return this._thinking; }
  set thinking(thinking) {
    this._thinking = thinking;
    this.notify("thinking");
    this.emit("changed");
  }

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
      "model": ["string", "rw"],
      "system-message": ["string", "rw"]
    });
  }

  _systemMessage = {
    role: "system",
    content: "You are Cody, an AI coding assistant from Sourcegraph."
  };

  _messages = [];
  _decoder = new TextDecoder();
  _model = "cody-v2";
  url = GLib.Uri.parse("https://api.sourcegraph.com/cody/v1/chat", GLib.UriFlags.NONE);

  constructor() {
    super();
    if (!Keys.SOURCEGRAPH_API_KEY) {
      console.error("Cody AI: API Key is not set!");
    }
  }

  getModels() {
    return ["cody-v2"];
  }

  set systemMessage(msg) {
    this._systemMessage.content = msg;
    this.notify("system-message");
  }

  get systemMessage() {
    return this._systemMessage.content;
  }

  set model(model) {
    if (!this.getModels().includes(model)) {
      console.warn("Model must be one of " + this.getModels());
      return;
    }
    this._model = model;
    this.notify("model");
  }

  get model() {
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

  readResponse(stream, codyResponse) {
    stream.read_line_async(0, null, (stream, res) => {
      if (!stream) return;
      const [bytes] = stream.read_line_finish(res);
      const line = this._decoder.decode(bytes ?? undefined);
      if (line && line != "") {
        try {
          const result = JSON.parse(line);
          if (result.type === "delta") {
            codyResponse.addDelta(result.content);
          }
        } catch {
          codyResponse.addDelta(line + "\n");
        }
      }
      this.readResponse(stream, codyResponse);
    });
  }

  async showError(stream, codyResponse) {
    if (!stream) return;
    const [data] = await stream.read_upto_async("\x04", -1, 0, null);
    if (data) {
      codyResponse.addDelta("```json\n" + data + "\n```");
    }
  }

  send(msg) {
    this.messages.push(new CodyMessage("human", msg));
    this.emit("newMsg", this.messages.length - 1);

    const codyResponse = new CodyMessage("assistant", "Thinking...", true);
    this.messages.push(codyResponse);
    this.emit("newMsg", this.messages.length - 1);

    const body = {
      messages: this.messages.map(msg => ({ speaker: msg.role, text: msg.content })),
      stream: true,
      model: this._model,
    };

    const session = new Soup.Session();
    const message = new Soup.Message({
      method: "POST",
      uri: this.url,
    });
    message.request_headers.append("Authorization", "token " + Keys.SOURCEGRAPH_API_KEY);
    message.set_request_body_from_bytes("application/json", new GLib.Bytes(JSON.stringify(body)));

    session.send_async(message, 0, null, (_, result) => {
      const stream = session.send_finish(result);
      const dataStream = new Gio.DataInputStream({
        close_base_stream: true,
        base_stream: stream
      });
      if (message.get_status() == 200) this.readResponse(dataStream, codyResponse);
      else this.showError(dataStream, codyResponse);
    });
  }
}

export default new CodyAIService();
