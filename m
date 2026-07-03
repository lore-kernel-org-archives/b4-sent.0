From: Chen Linxuan <me@black-desk.cn>
Subject: [PATCH v6 0/2] includeIf: add "worktree" condition for matching
 working tree path
Date: Fri, 03 Jul 2026 11:13:16 +0800
Message-Id: <20260703-includeif-worktree-v6-0-a13893ad9a7f@black-desk.cn>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAMwoR2oC/33QwU7DMAwG4FeZcibIcZq04cR7IA5N4rCoU4uSU
 UBT3x13FyoRcfxt+bPlm6hUMlXxdLqJQmuueZk52IeTCOdxfiOZI2eBgBY6UDLP4fIRKSf5uZT
 pWohkCt52zkBMfhQ8+F4o5a87+vLK+ZzrdSnf9x2r2qv/cquSIB3Y6K1LGHr37C9jmGSkOj2GW
 ezkikcGmwwyoy1p7fzghti3GH1kdJPRzChwgUw/oAfdYrpfxqg20zGTBrKoMCp+VIsxBwZNkzH
 7NZSI+xHQ/GG2bfsBK1CJWdQBAAA=
X-Change-ID: 20260401-includeif-worktree-fcb64950dfba
To: git@vger.kernel.org
Cc: Kristoffer Haugsbakk <kristofferhaugsbakk@fastmail.com>, 
 Junio C Hamano <gitster@pobox.com>, Patrick Steinhardt <ps@pks.im>, 
 Chen Linxuan <me@black-desk.cn>, Phillip Wood <phillip.wood@dunelm.org.uk>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=openpgp-sha256; l=3324; i=me@black-desk.cn;
 h=from:subject:message-id; bh=srt1rc2zixmmVAlprY6nwCXBccVgmX6AJVS0VWVd9i0=;
 b=owEBbQKS/ZANAwAKAXYe5hQ5ma6LAcsmYgBqRyjVB+5fVsJcBdtNixvdfXIBoMdgSVP1H+FDH
 O4zU0v3x4aJAjMEAAEKAB0WIQTO1VElAk6xdvy0ZVp2HuYUOZmuiwUCakco1QAKCRB2HuYUOZmu
 i5WYD/wJUJB+1ymfyiXBDJpqDJT7DKWN0P2ZiYZuIvxjUtwZj6DwbQ7yHT5MAnuEH5hiT3YMtM0
 rMiQLAjSGzaYCDZrHENWmoEenTEnprS6FX4ei9vQnjL/QDtqv8Baki4Io8ix2J6TVnPNFKjmhwj
 a5TMXCKx4z5n03b4E+VAIFVf7Vi3l7GkLgIdmxEnEQOYwhEWM5e3NlwmUeWFszvik8kdoK9Dojv
 dMyrzcQ7j3f1226+4KPmu8+LXbw8zjS4sL3K0AZDFDZyD1U1j8I5nz4FT5ZlfYgWMNlt3FBhe/+
 rL+tWiKesrt5Ny/iDyCZWefXCaGcb0i0cuZKPAJG2f3d0dMMQuuXWWwXt/hXc4UE0Sgh/nBOdX7
 d3FiI+0Rg8+xCLFRIAB9jzoEvUndEHUhBcj1kScy8Ais4vN4QDreQPdgIw5GWZUp9U1/Jg/1Unh
 EDj6wjNCi0BGx3BoafyhE0ewhE5XJC7EESvwTsHvq8oMhxZ1YnX7Rr/K1mXxtkzoXkOV26v5y7n
 B06VA4K8gnlXZIzL+I8RDBWeB4Pn3+Q3GCblZakCbpoz/oClIPd7CV/rMhtQf+y0NH0Kxt9Y0mF
 Zmci1Y6NjGT0JN03GwsQ8VFVzGt/jv8TEMarbCyKmiShEkzVZaLuSxGS1yeWMVOBtogmev4LX59
 4JzBXCDSD3E1h7g==
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
Changes in v6:
- Rebase onto current `master` at Git 2.55.
- Add an in-code comment explaining why the non-repository worktree
  tests use the loose `**.path` pattern (suggested by Junio C Hamano).
- Link to v5: https://lore.kernel.org/r/20260525-includeif-worktree-v5-0-1efe525d025a@black-desk.cn

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

 Documentation/config.adoc |  48 +++++++++++++++++
 config.c                  |  25 +++++----
 t/t1305-config-include.sh | 128 ++++++++++++++++++++++++++++++++++++++++++++++
 3 files changed, 190 insertions(+), 11 deletions(-)
---
base-commit: e9019fcafe0040228b8631c30f97ae1adb61bcdc
change-id: 20260401-includeif-worktree-fcb64950dfba

Best regards,
-- 
Chen Linxuan <me@black-desk.cn>

