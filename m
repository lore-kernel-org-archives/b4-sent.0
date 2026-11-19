From: Eslam Almorshdy <ealmorshdy@d-matrix.ai>
Subject: [PATCH v2 0/2] Fix a readlink() typo in Psystem_daemon()
Date: Thu, 19 Nov 2026 07:11:40 +0000
Message-Id: <20261119-b4-bug008-daemon-readlink-v2-0-c4bc5fbf156f@d-matrix.ai>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/42NTQ6CMBBGr0K6dkynKKAr72FY9GeAUSmmBYIh3
 F3AC7h8yfveN4tIgSmKazKLQCNH7vwK6pAI22hfE7BbWSipMkQswJzADLWUBThNbechkHYv9k/
 IckpTiWll7Fms+3egiqe9fS9/HAfzINtvwc1oOPZd+OznI27ePz8jggQscnsho5RDvDlodR94O
 moW5bIsX4xWZyPWAAAA
X-Change-ID: 20261118-b4-bug008-daemon-readlink-67e33013fbc5
To: dtrace@lists.linux.dev
Cc: Nick Alcock <nix@esperi.org.uk>, 
 Kris Van Hees <kris.van.hees@oracle.com>, 
 Eslam Almorshdy <ealmorshdy@d-matrix.ai>
X-Mailer: b4 0.16.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1795072309; l=1174;
 i=ealmorshdy@d-matrix.ai; s=20261015; h=from:subject:message-id;
 bh=O9ZxxWCzSpnDvu7L3W+H3IcaMBTRbBPC9pJO5VMeoiQ=;
 b=mAlxtV/SgZG7Dnb6mENRAD7iOfpRVXmF6nV395DXsB3xqramcPJOgnIAY1At4uVkMSZPQnMvP
 zAQNAC3G8q2D68Bh3sSilYYqQW1dQlnf0skZn3D5e+9DUExLwAq6hYi
X-Developer-Key: i=ealmorshdy@d-matrix.ai; a=ed25519;
 pk=E4tVAIvp2rvz2CB7Re6YVMP6FiUVSxuq0TUtjGQL5NM=
X-Endpoint-Received: by B4 Relay for ealmorshdy@d-matrix.ai/20261015 with auth_id=1187
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Psystem_daemon() tests readlink() == 0, but readlink() returns the
number of bytes stored or -1, so the "regular file outside /var" rule
never applied: every root process without a terminal was a system
daemon wherever systemd doesn't decide.

Patch 1 is the one-character fix.  Patch 2 adds a test that hides
/run/systemd with unshare, so the rule is exercised on systemd hosts
too.  On systems without systemd Patch 1 also turns pid/tst.emptystack,
tst.float, tst.manypids and tst.probemod green.

Changes since v1:
- Patch 2: moved the /var guard up and used [[ ]] (Kris).

---
Eslam Almorshdy (2):
      libproc: fix readlink() typo in Psystem_daemon()
      test: add test for system daemons with regular files as streams

 libproc/Pcontrol.c                            |  2 +-
 test/unittest/proc/tst.system-daemon-files.r  |  2 +
 test/unittest/proc/tst.system-daemon-files.sh | 95 +++++++++++++++++++++++++++
 3 files changed, 98 insertions(+), 1 deletion(-)
---
base-commit: 61fea621160ea4b6302874c62a723da105b44883
change-id: 20261118-b4-bug008-daemon-readlink-67e33013fbc5

Best regards,
--  
Eslam Almorshdy <ealmorshdy@d-matrix.ai>

