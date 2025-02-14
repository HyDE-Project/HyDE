const fetch = require('node-fetch'); // Jika Anda menggunakan Node.js, pastikan untuk menginstal `node-fetch`

const query = `
  query {
    currentUser {
      username
    }
  }
`;

const token = 'sgp_fd1b4edb60bf82b8_f136bfd9e2b6cb5a6865359cd28f2ab13dc3d33b';

fetch('https://sourcegraph.com/.api/graphql', {
  method: 'POST',
  headers: {
    'Content-Type': 'application/json',
    'Authorization': `token ${token}`,
  },
  body: JSON.stringify({ query })
})
  .then(response => response.json())
  .then(data => console.log(data))
  .catch(error => console.error('Error:', error));

export const TOKEN = token;