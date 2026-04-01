From: Chen Linxuan <me@black-desk.cn>
Subject: [PATCH 0/3] includeIf: add "worktree" condition for matching
 working tree path
Date: Wed, 01 Apr 2026 15:33:40 +0800
Message-Id: <20260401-includeif-worktree-v1-0-906db69f2c79@black-desk.cn>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAFXKzGkC/x3MTQqAIBBA4avIrBM0KqirRIvSsYZCY+wPpLsnL
 b/FewkiMmGETiRgvChS8Bm6EGCW0c8oyWZDqcpGVUpL8mY7LZKTd+D1YETpzNRUba2sm0bI4c7
 o6Pmn/fC+Hwi2MjlkAAAA
X-Change-ID: 20260401-includeif-worktree-fcb64950dfba
To: git@vger.kernel.org
Cc: Chen Linxuan <me@black-desk.cn>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=openpgp-sha256; l=1485; i=me@black-desk.cn;
 h=from:subject:message-id; bh=Ox/TZ26WTiQUgMpzZRDUQr/ZgrIrJkCzCVOAuiq+1Cs=;
 b=owEBbQKS/ZANAwAKAXYe5hQ5ma6LAcsmYgBpzMpppH9FHw0IVNzRMUISzajiDmC+BmCKrQDpe
 B8OyhUpEwmJAjMEAAEKAB0WIQTO1VElAk6xdvy0ZVp2HuYUOZmuiwUCaczKaQAKCRB2HuYUOZmu
 iyEjD/0bb0dum+n2CFyCFMEpbU6dzIkp0uf1Vvbtu9xIi9b61anCeYmHzR4vvVn2fk80YYd5iKf
 YX+gsV7SEHeGjrwPBWUqOiZZI6j/GauvMAtRO74LTGFk1GtS0u43ZCNhejN2I67xd9kkMM+782J
 2YHRzRJ36T7B8QiHj8as0yu1bSQZ9XBniO6cuEw+1yKzi65mMF+391zRTmLWtmuyDMhOActiy5S
 rLoiSIH9yD/XH+ygd6ulFJLR4vDIQeBFmXLk/sQvSC0Dasp5OvSMHK2Gy9HGq6IB2BtXfmz10bG
 wK/cyc/JLKf9M9fIMfbRinj7mfmsj0UNaF6B/EiVXyWChKO/rXnlULvUmfarCbzrGEQbLLU32IW
 phm7LCSgVpU8rI16ry15xwiAybc5wFdWbWe67OmF3bxH5453QFt/8kOgV2+dTdLGZwN35dWuSeS
 pU2DmiEdOC2p1egWBoGqIuxguqM39mQUD6DwtuU+upXCbcZjMlpYzU5kffaUYxa89FcGho+ztnn
 +/SJilFi2tmv5wWrLfcmGmrCW2eEiR5OLmuuWBGYgHN0xfa9Fbeuj5WZjJtRHo4c/f9qag4WdLy
 qDuuZpAGVGcNcy7Zse3FM6DSZHS/aU3F8sg2uMl0/l+3aLpcsAxaIHe5EDGyc2e51HFstR+V/in
 fCqYwPmWRYEb7zQ==
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
Chen Linxuan (3):
      config: add "worktree" and "worktree/i" includeIf conditions
      Documentation/config: add includeIf "worktree"
      t1305: add tests for includeIf "worktree"

 Documentation/config.adoc | 50 +++++++++++++++++++++++++++++++++++
 config.c                  | 25 ++++++++++--------
 t/t1305-config-include.sh | 66 +++++++++++++++++++++++++++++++++++++++++++++++
 3 files changed, 130 insertions(+), 11 deletions(-)
---
base-commit: 270e10ad6dda3379ea0da7efd11e4fbf2cd7a325
change-id: 20260401-includeif-worktree-fcb64950dfba

Best regards,
-- 
Chen Linxuan <me@black-desk.cn>

