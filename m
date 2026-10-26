From: Daejun Park <daejun7.park@samsung.com>
Subject: [PATCH 0/2] xfs: discard every free extent in a whole-AG FITRIM
Date: Mon, 26 Oct 2026 10:54:04 +0900
Message-Id: <20261026-xfs-fitrim-skip-v1-0-cddd8414f99c@samsung.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIALyy3moC/x3MSQqAMAxA0auUrA20dQKvIi6kJhrEgUZEKN7d4
 vIt/k+gFIUUOpMg0i0qx57hCgNhGfeZUKZs8NY3zvoSH1ZkuaJsqKuc2DK7wLZsqlBDrs5ILM9
 /7If3/QA0pdLzYQAAAA==
To: Carlos Maiolino <cem@kernel.org>, linux-xfs@vger.kernel.org
Cc: "Darrick J. Wong" <djwong@kernel.org>, Dave Chinner <dgc@kernel.org>, 
 Christoph Hellwig <hch@lst.de>, linux-kernel@vger.kernel.org, 
 stable@vger.kernel.org, Daejun Park <daejun7.park@samsung.com>
X-Mailer: b4 0.13.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1792979644; l=823;
 i=daejun7.park@samsung.com; s=20261006; h=from:subject:message-id;
 bh=IkSnMGO4RLkaGK9K0XCl13Zs2nXzPjRFhg/jdMsWFtA=;
 b=vRZMtnQaD1kclpEj1aOKEIogO+2AExrRgNiakFIHTsTuDDp9Cx/Q9NjskiiJJ2CfSmcO6I/N5
 bl4C3E3lbWOBajcz/1hBhDdV9oU7iUgD4LImQC9Hrjtnsl/zH/0vcMh
X-Developer-Key: i=daejun7.park@samsung.com; a=ed25519;
 pk=4yUfDqGRZTIj0Ik43z1GoMZRWCNm/rgX6uJuM9dtNIg=
X-Endpoint-Received: by B4 Relay for daejun7.park@samsung.com/20261006 with auth_id=1122
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

A whole-device fstrim walks each AG but the last by length. Two bugs
in that walk leave free extents undiscarded, while fstrim reports the
whole range as trimmed. Patch 2 depends on patch 1.

The new fstests case xfs/842, sent separately, fails without this
series and passes with it. ./check -g trim shows no regressions
(generic/038 and 500 were not run).

---
Daejun Park (2):
      xfs: don't skip free extents in later batches of a whole-AG FITRIM
      xfs: don't skip free extents of the longest length in a whole-AG FITRIM

 fs/xfs/xfs_discard.c | 26 ++++++++++++++++++--------
 1 file changed, 18 insertions(+), 8 deletions(-)
---
base-commit: ec8f62cc109a3f596b3c65dc0f1011c209239051
change-id: 20261023-xfs-fitrim-skip-7ff1cf0364c5

Best regards,
-- 
Daejun Park <daejun7.park@samsung.com>

