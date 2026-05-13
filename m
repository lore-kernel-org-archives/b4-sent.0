From: Chen Linxuan <me@black-desk.cn>
Subject: [PATCH v4 0/2] includeIf: add "worktree" condition for matching
 working tree path
Date: Wed, 13 May 2026 16:08:16 +0800
Message-Id: <20260513-includeif-worktree-v4-0-f8e6212d1fba@black-desk.cn>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAHAxBGoC/33NTQ6CMBCG4auQrq3pDxTqynsYF7SdSoMppsWqI
 dzdwooY4vL9knlmQhGCg4hOxYQCJBfd4HOUhwLprvU3wM7kRowwQUpCsfP6/jTgLH4NoR8DALZ
 aiVJWxFjVonz4CGDde0Uv19ydi+MQPuuPRJf1L5coJlgSYZSQlulantW91T02EPuj9mghE9syb
 JdhmeECOJeqkY2p9xi+ZfguwzNDidRQ1Q1ThP8y8zx/AT0B2wRGAQAA
X-Change-ID: 20260401-includeif-worktree-fcb64950dfba
To: git@vger.kernel.org
Cc: Kristoffer Haugsbakk <kristofferhaugsbakk@fastmail.com>, 
 Junio C Hamano <gitster@pobox.com>, Patrick Steinhardt <ps@pks.im>, 
 Chen Linxuan <me@black-desk.cn>, Phillip Wood <phillip.wood@dunelm.org.uk>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=openpgp-sha256; l=2490; i=me@black-desk.cn;
 h=from:subject:message-id; bh=bbMfNOcsXSiZIgD1VMa7qXLSXzdS+bvBNWvJyJ0pnLw=;
 b=owEBbQKS/ZANAwAKAXYe5hQ5ma6LAcsmYgBqBDF+VJdhN8laiueYnD/2/KfIFISfFLx7NsJNK
 33C+RNobumJAjMEAAEKAB0WIQTO1VElAk6xdvy0ZVp2HuYUOZmuiwUCagQxfgAKCRB2HuYUOZmu
 i5EeD/42Vw2YFsOSLe20nHuFt/DsZ2w2C8mABSRY31mYO57J8uaaI26aLb0mJN2HE4a/eiVbeG/
 KlepAi+Q/x8k93wm6MzGhMTiDvl3sYeUpv4taRK65V4JGXhtMjEFUBXxgBylrLVMiM093WY+xMz
 bIyjyykePPeS/v52qMecDsjS6EoH3QXbmeGpt06AInBDxA2F6ccPxl4ulLMMzQ+mo7ocOKxqt71
 gwIFLq81tsmrhNJQuy1AhIdtPcgFpX8ZRNWpzH9IZ4TxN+r/tSPRFHh6bkzuYHrvzj4CKxZ37of
 N34CCyPUo/3MTMgJzVRa8oHLkUJ/YqMdPz4A37f6UOurYAEKxJRTb+oPF6lbTznT5f4PJgqT4Hm
 QGlgL5amjBp34qVvzyZ3PLyGP4fSjpscSykEl3GUYrnOJT2dNHlQsvljbSn15DfTH2mCj+l9+ma
 AecvJratCRua2uXkZSzAG53SZuXIZFYLRQ1dpY+JWwhucQ0Q6S3ZQ/LdAgdN3vkXJFcalnri/FV
 bLtozOHK6qRo67+Loc27966xpafkXchA7qcg3/k44cOmCRznNMQAMywmzqnOwAxL432nSVRFpjg
 YJmorDsHexh1zd2hkHQA3brQAWAGsv0uhV1VE4k4s4TepA1ssZQWIa2OpL11+qTU9J7ejlIa77i
 pukllX0Ru/on+Yw==
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

 Documentation/config.adoc |  48 ++++++++++++++++++++
 config.c                  |  25 +++++-----
 t/t1305-config-include.sh | 113 ++++++++++++++++++++++++++++++++++++++++++++++
 3 files changed, 175 insertions(+), 11 deletions(-)
---
base-commit: 270e10ad6dda3379ea0da7efd11e4fbf2cd7a325
change-id: 20260401-includeif-worktree-fcb64950dfba

Best regards,
-- 
Chen Linxuan <me@black-desk.cn>

