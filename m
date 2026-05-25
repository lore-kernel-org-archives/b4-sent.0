From: Chen Linxuan <me@black-desk.cn>
Subject: [PATCH v5 0/2] includeIf: add "worktree" condition for matching
 working tree path
Date: Mon, 25 May 2026 11:20:07 +0800
Message-Id: <20260525-includeif-worktree-v5-0-1efe525d025a@black-desk.cn>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAOe/E2oC/33QwQ7CIAyA4VdZOIuBsrHhyfcwHgYUJVs2A3Nql
 r276EVjiMe/Sb8mXUjE4DGSXbGQgLOPfhxSVJuCmHM7nJB6m5oAA8lKxqkfTH+16B29jaGbAiJ
 1RstSVcw63ZK0eAno/P2NHo6pzz5OY3i8b8z8Nf3LzZwyqpi0WioHplZ73bemoxZjtzUDeZEzf
 DOQZSAxQqIQSjeqsXWOEd+MyDIiMZwpg1XdgGYix5QfpuJ5pkyMa1ACB8vTo36ZdV2f4V4z940
 BAAA=
X-Change-ID: 20260401-includeif-worktree-fcb64950dfba
To: git@vger.kernel.org
Cc: Kristoffer Haugsbakk <kristofferhaugsbakk@fastmail.com>, 
 Junio C Hamano <gitster@pobox.com>, Patrick Steinhardt <ps@pks.im>, 
 Chen Linxuan <me@black-desk.cn>, Phillip Wood <phillip.wood@dunelm.org.uk>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=openpgp-sha256; l=3020; i=me@black-desk.cn;
 h=from:subject:message-id; bh=2PpbGKOFrg4dLIvLUnoHgnONdgQmeCgpBQyBhuvFDo0=;
 b=owEBbQKS/ZANAwAKAXYe5hQ5ma6LAcsmYgBqE7/sHurlLhu/yNImoVPP+yVkOCdEEQAaPbERw
 LDgllgpwgmJAjMEAAEKAB0WIQTO1VElAk6xdvy0ZVp2HuYUOZmuiwUCahO/7AAKCRB2HuYUOZmu
 izoWD/wNB5S9GN9B4yILszyEe25Dw+2kQ6Mmu/Lbnk1lOU4n2ZSCeHDhZzBmy1mEodcr0mTfiWJ
 sypRUPkdYTdzbllD0GbPAByWR42Da6ba66YqjBgGw3z1kybPGZHyu+gkkLyVvkHl4GQ74hXyu3D
 2cqLAOO0JpposEYfPo2cC4kjMGGnz9b9+MN9nQqMo1FeUT2W59x6CoPmxjMXq1fahn2UJH7NZgn
 YfK+ihINC3N7nEMU++rpCfrsqg0ZLRJGyb7RfeTTcuGmxNfdKSBmoKBSJrCQJHCcAbB6Ta+2hpc
 PIF2bKLFylK7QBbYCME8xXET74bM4adU5vn+UK7Di+ixCINhdzCgrNRWwwYTcCkpjXR2jgJHUmW
 ih4trpRRrr7ICjuXajdXLVBlr1gvavp9AJI2Gv2YoZnEvXPW9jDQ76gIgM9+vLb5ut5TVSC0iH7
 VMnoD91yuZeSjGtblVsjSb1sKuGGj7D45TDDMxoWOvj2pBG7d7Ii8MmoOhHX79bZZ12EcNp8s3x
 i1B33mKD6AHyZkJJBSLCWH+5kyJ2ltFZ+lYMcwMLQhpjtvBbJ0hOXdtzmd0PS5uuzG0SdBAWbvd
 r0saPGQr3nCU9f5TCj7Z+vh8NqZhb+JEzvgE9QSGeiw1LDe5SIv0LUKDfT1H0Gmz68bFDks5nww
 XnulBp02Gdm5z+Q==
X-Developer-Key: i=me@black-desk.cn; a=openpgp;
 fpr=D818ACDD385CAE92D4BAC01A6269794D24791D21
X-Endpoint-Received: by B4 Relay for me@black-desk.cn/default with auth_id=573
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The `includeIf` mechanism already supports matching on the `.git`
directory path (`gitdir`) and the currently checked out branch
(`onbranch`).  But in multi-worktree setups the `.git` directory of a
linked worktree points into the main repository's `.git/worktrees/`
area, which makes `gitdir` patterns cumbersome when one wants to
include config based on the working tree's checkout path instead.

Introduce two new condition keywords:

  - `worktree:<pattern>` matches the realpath of the current worktree's
    working directory against a glob pattern.
  - `worktree/i:<pattern>` is the case-insensitive variant.

Supported pattern features: glob wildcards, `**/` and `/**`, `~`
expansion, `./` relative paths, and trailing-`/` prefix matching.
The condition never matches in a bare repository.

Signed-off-by: Chen Linxuan <me@black-desk.cn>
---
Changes in v5:
- Fix Windows CI failure: use `**` glob pattern instead of `/` in the
  "worktree without repository" tests, since `/` as a path pattern is
  Unix-specific and does not match Windows paths.
  Github CI pass: https://github.com/black-desk/git/actions/runs/26380466288
- Add a test verifying case-sensitive matching by default, with the
  `!CASE_INSENSITIVE_FS` prerequisite (suggested by Patrick Steinhardt).
- Link to v4: https://lore.kernel.org/r/20260513-includeif-worktree-v4-0-f8e6212d1fba@black-desk.cn

Changes in v4:
- Deduplicate the worktree pattern documentation by referencing the
  gitdir syntax instead of repeating the full pattern description
  (suggested by Patrick Steinhardt).
- Add documentation comparing includeIf "worktree:" with
  extensions.worktreeConfig, including a concrete use case example
  (suggested by Phillip Wood, Junio C Hamano).
- Add a test verifying that the worktree condition does not match
  during early config reading (suggested by Patrick Steinhardt).
- Add tests for the non-repository (nongit) scenario (suggested by
  Patrick Steinhardt).
- Add a test for the case-insensitive "worktree/i" variant
- Link to v3: https://lore.kernel.org/r/20260403-includeif-worktree-v3-0-109ce5782b03@black-desk.cn

Changes in v3:
- Apply Junio's suggestion.
- Link to v2: https://lore.kernel.org/r/20260402-includeif-worktree-v2-0-36e339b898d7@black-desk.cn

Changes in v2:

- Add missing signed-off-by lines.
- Link to v1: https://lore.kernel.org/r/20260401-includeif-worktree-v1-0-906db69f2c79@black-desk.cn

---
Chen Linxuan (2):
      config: refactor include_by_gitdir() into include_by_path()
      config: add "worktree" and "worktree/i" includeIf conditions

 Documentation/config.adoc |  48 ++++++++++++++++++
 config.c                  |  25 +++++----
 t/t1305-config-include.sh | 126 ++++++++++++++++++++++++++++++++++++++++++++++
 3 files changed, 188 insertions(+), 11 deletions(-)
---
base-commit: 56a4f3c3a221adf1df9b39da69b8a6890f803157
change-id: 20260401-includeif-worktree-fcb64950dfba

Best regards,
-- 
Chen Linxuan <me@black-desk.cn>

