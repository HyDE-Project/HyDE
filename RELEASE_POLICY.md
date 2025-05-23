## Release & Branching Policy (Flexible Freeze & Release Window)

### Branches

- **`dev` branch**  
  Active development branch where all new features and fixes are merged and tested continuously.

- **`master` branch**  
  Stable production branch updated only with thoroughly tested code from `dev`.

- **`release` branch**
  Freezed production `master` branch for release. This branch is not updated with new features or fixes. This just serves as a snapshot of the production code.

### Weekly Release Cycle (Flexible Timing)

- **Dev Branch Freeze Window:**  
  The `dev` branch freeze typically occurs **during the latter part of the week (Wednesday/Thursday)**, allowing no new feature merges after that point. Only critical bug fixes and final testing are allowed during this freeze period.

- **Merge & Release Window:**  
  The merge from `dev` to `master` and deployment to production happens **on Friday**.

- **Freeze & Release Window:**  
  The freeze and release window is we can freeze and tag the `master` branch. Cycles should be first and third week per month.

### Development and Testing

- **Monday to Wednesday (before freeze):**  
  Developers merge features and fixes into `dev`. Testers validate continuously.

- **Thursday (freeze window):**  
  Development freezes on `dev` at some point during the day. Testers focus on final validation and regression testing.

- **Friday (release window):**  
  Once `dev` is stable and approved, it is merged into `master` and deployed. This happens sometime during Friday, with flexibility to ensure quality.

- **Friday to Sunday:**  
  Production monitoring and hotfix as needed.

### Pull Requests

- All pull requests should be made against `dev` branch.
- Pull requests should be reviewed and approved by at least one other developer before merging.
- Pull requests should be merged and deployed within the release window for `master` branch.
- Pull requests should not be merged directly into `master` branch.
- Pull request can be created anytime, but should be reviewed and and should be merged to `dev` branch before releasing on `master` branch.

### Summary Timeline (Flexible)

| Day                              | Activity                                               |
| -------------------------------- | ------------------------------------------------------ |
| Monday–Wednesday (before freeze) | Active development and testing on `dev` branch         |
| Thursday (freeze window)         | Freeze `dev` branch at flexible time; finalize testing |
| Friday (release window)          | Merge `dev` into `master` and deploy at flexible time  |
| Friday–Sunday                    | Monitor production and prepare hotfixes if needed      |

---

### Notes

- The freeze and release times are **flexible within late Wednesday and Friday** to accommodate testing needs and ensure release quality.
- Aim to freeze `dev` as early as possible on Wednesday and release early on Friday, but timing may adjust based on readiness.
- Clear communication will be provided each week about the expected freeze and release times. Expect that it may be in the commit messages or in a dedicated discord channel.
- This is yet experimental and may be adjusted or modified based on feedback and testing results.
- We don't have exact time frames as it depends on the collaborators availability.
