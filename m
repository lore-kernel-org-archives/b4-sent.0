From: Chen Linxuan <me@black-desk.cn>
Subject: [PATCH v2 0/3] includeIf: add "worktree" condition for matching
 working tree path
Date: Thu, 02 Apr 2026 10:58:44 +0800
Message-Id: <20260402-includeif-worktree-v2-0-36e339b898d7@black-desk.cn>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAGTbzWkC/32NTQ6CMBBGr0Jm7ZjSYE1deQ/Doj9TmZQU0yJqC
 He3cgCX7yXf+1YolJkKXJoVMi1ceEoV5KEBN5h0J2RfGaSQSnSiRU5ufHrigK8pxzkTYXBWdfo
 kfLAG6vCRKfB7j976ygOXecqf/WNpf/ZvbmlRoBbKW6WDdGd9taNxET2VeHQJ+m3bvmuBZsK4A
 AAA
X-Change-ID: 20260401-includeif-worktree-fcb64950dfba
To: git@vger.kernel.org
Cc: Kristoffer Haugsbakk <kristofferhaugsbakk@fastmail.com>, 
 Chen Linxuan <me@black-desk.cn>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=openpgp-sha256; l=1647; i=me@black-desk.cn;
 h=from:subject:message-id; bh=Q8VmkXQvpMBDCjFQlGFLOrNMmWMHiShvAqOXZB4T/lI=;
 b=owEBbQKS/ZANAwAKAXYe5hQ5ma6LAcsmYgBpzdtnewW4nd/lVM3hzyBmw6A9EXI4BwHybc6G4
 a4caHiK3NSJAjMEAAEKAB0WIQTO1VElAk6xdvy0ZVp2HuYUOZmuiwUCac3bZwAKCRB2HuYUOZmu
 i8HWD/9FlkQ3qnQDjiH3UyGRtgBCot2vnKUNOgQIzgsGbY/AKfU/9DDNSHPoqY2Q2vNzfwllQkS
 Ce8pL8WHv7DWdEcF7TBrhcrzNjVGZh7nCqD+oZKAiTprZrg7SZuJt3sNOKYaUxwT92s+DbN/nge
 inWW0D2TUb7I3RMUL0MIktrIR/NJhjXkx5FU6f0tKS2uUsiuFi2eXS3redxROi4hljVnI3Uy5KY
 tw6vXYvWclv56bJtnGPFFrKz6hMH80dYkOZuQlCmocZOcxDKEYCS02yIrl39wkYyWHnZFxR8R3n
 mnc6LiDo2sb0qZRxCZiIiLvh+yH7cJv2dufDtbocBcH+oH/dw0S0q/eF1Wt/9rPXABdmYNHCEun
 ivw4dkEQlADxfDeyy5No3J7L58+jfDt5il3quemZZd8THjmBIqFHsShi5kq+ANph7yBrdHyFkS9
 bgbzGHpA6xf7KLiBh4V/0oOWJ/kKhicld6V5s143vDkuM9MpUaAC8qcKPmQxiI+3I73Ev8FmPVh
 tiv5meg0DdODVlN2UjxfYSbF970Iju9yihzn2a+kjcjWFPIASD6oQX7amYLnJWBM1AzxEyy4n6y
 MnjSXZAglzfLhlZiaTer4eGm1w0A1UEWRZ/dGKM9QyaN/w68t6QOeu78J7DgGjAQM6V+/eDQXbk
 Po/CPumiWs/1lDw==
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
Changes in v2:

- Add missing signed-off-by lines.
- Link to v1: https://lore.kernel.org/r/20260401-includeif-worktree-v1-0-906db69f2c79@black-desk.cn

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

