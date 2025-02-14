curl \
  -H 'Authorization: token sgp_fd1b4edb60bf82b8_f136bfd9e2b6cb5a6865359cd28f2ab13dc3d33b' \
  -d '{"query":"query { currentUser { username } }"}' \
  https://sourcegraph.com/.api/graphql