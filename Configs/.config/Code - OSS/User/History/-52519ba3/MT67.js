import Gio from 'gi://Gio';
import Soup from 'gi://Soup';
import GLib from 'gi://GLib';

const query = `
  query {
    currentUser {
      username
    }
  }
`;

const token = 'sgp_fd1b4edb60bf82b8_f136bfd9e2b6cb5a6865359cd28f2ab13dc3d33b';

function fetchData() {
    const session = new Soup.Session();
    const message = Soup.Message.new('POST', 'https://sourcegraph.com/.api/graphql');

    message.request_headers.append('Content-Type', 'application/json');
    message.request_headers.append('Authorization', `token ${token}`);

    const body = JSON.stringify({ query });
    message.set_request_body_from_bytes('application/json', new TextEncoder().encode(body));

    session.send_and_read_async(message, GLib.PRIORITY_DEFAULT, null, (_, result) => {
        try {
            const bytes = session.send_and_read_finish(result);
            const decoder = new TextDecoder('utf-8');
            const response = JSON.parse(decoder.decode(bytes.get_data()));
            console.log(response);
        } catch (error) {
            console.error('Error:', error);
        }
    });
}

fetchData();

export const TOKEN = token;
