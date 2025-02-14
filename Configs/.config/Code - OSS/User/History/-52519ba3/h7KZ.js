const Gio = imports.gi.Gio;
const GLib = imports.gi.GLib;

const query = `
  query {
    currentUser {
      username
    }
  }
`;

const token = 'sgp_fd1b4edb60bf82b8_f136bfd9e2b6cb5a6865359cd28f2ab13dc3d33b';

// Membuat HTTP request menggunakan Gio
function makeGraphQLRequest() {
  const url = 'https://sourcegraph.com/.api/graphql';
  const requestBody = JSON.stringify({ query });

  const session = new Gio.Session();
  const message = new Gio.Message({
    method: 'POST',
    uri: url,
  });

  message.request_headers.append('Authorization', `token ${token}`);
  message.request_headers.append('Content-Type', 'application/json');

  // Menambahkan body JSON ke dalam request
  message.set_request_body_from_bytes(GLib.Bytes.new(requestBody));

  session.send_message_async(
    message,
    null,
    function(session, result) {
      try {
        const response = session.send_message_finish(result);
        const statusCode = response.get_status();

        if (statusCode === 200) {
          const responseBody = response.get_response_body().flatten().get_data();
          const jsonResponse = JSON.parse(responseBody);
          log(JSON.stringify(jsonResponse));  // Print hasil query GraphQL
        } else {
          log(`Error: Received status code ${statusCode}`);
        }
      } catch (e) {
        log(`Request failed: ${e.message}`);
      }
    }
  );
}

makeGraphQLRequest();

export const TOKEN = token;
