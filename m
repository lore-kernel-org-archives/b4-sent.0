From: "Mark C. Chu-Carroll" <markchucarroll@fastmail.com>
Subject: [PATCH v2 0/3] Update t40* tests to use modern style.
Date: Thu, 10 Sep 2026 13:07:32 -0400
Message-Id: <20260910-modernize-t4001-v2-0-ac53e9f5d717@fastmail.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/3WNQQ6CMBBFr2Jmbc20JSquvIdhMZSpjBFq2kpUw
 t0FXLt8yfvvj5A4Cic4bUaIPEiS0M9gthtwLfVXVtLMDAbNHks8qi40HHv5sMoFola+LqxF44h
 8CfPqEdnLay1eqh+nZ31jl5fMYrSScojv9XLQi/e/PmiFylFtS2tJH6w/e0q5I7nvXOigmqbpC
 8JO5cvDAAAA
X-Change-ID: 20260908-modernize-t4001-fb43302caaf9
In-Reply-To: <20260908-modernize-t4001-v1-0-cab3933a173f@fastmail.com>
References: <20260908-modernize-t4001-v1-0-cab3933a173f@fastmail.com>
To: git@vger.kernel.org
Cc: "Mark C. Chu-Carroll" <markchucarroll@fastmail.com>
X-Mailer: b4 0.16.0
X-Developer-Signature: v=1; a=openpgp-sha256; l=1308;
 i=markchucarroll@fastmail.com; h=from:subject:message-id;
 bh=CA9yrxQUt4PlZC34oSgrFs5ZHGHGZupY9A3VOEHg8y4=;
 b=owGbwMvMwCUWOPFJle/8tn2Mp9WSGLIWPX7yeU12P0fsh0Ndm5Z9vrhlys6sS6lnPArm50kpR
 FyyDP0i0lHKwiDGxSArpsjy/59A4yuWBxJ+Qe8+wcxhZQIZwsDFKQATucrNyDDlr7VxZ8Cpzcq5
 e5TLX219cjX2lWCAyGyO7c7cLHHJQlUMf3h4crVOnDjyoPzv2mzz7f7HBG33rIq1WdZ6zZXXyoX
 XgRsA
X-Developer-Key: i=markchucarroll@fastmail.com; a=openpgp;
 fpr=FFFE1081EA04E0184E52EEF25191E47A4D9F86BE
X-Endpoint-Received: by B4 Relay for markchucarroll@fastmail.com/default with auth_id=1002
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

To: git@vger.kernel.org
Signed-off-by: Mark C. Chu-Carroll <markchucarroll@fastmail.com>

Changes in v2:
- Merged setups into main test bodies.
- Removed unnecessary echos.
- Cleaned up here-docs.
- Updated names to modern style.

- Link to v1: https://patch.msgid.link/20260908-modernize-t4001-v1-0-cab3933a173f@fastmail.com

---
Mark C. Chu-Carroll (3):
      Update t4001 to use modern syntax.
      Update t4009 to use modern style.
      Update t4010 to use modern style.

 t/t4001-diff-rename.sh   |  97 ++++++++++++++++-------------------
 t/t4009-diff-rename-4.sh | 131 +++++++++++++++++++++++------------------------
 t/t4010-diff-pathspec.sh |  88 +++++++++++--------------------
 3 files changed, 137 insertions(+), 179 deletions(-)

Range-diff versus v1:

1:  d55c790b60 < -:  ---------- Update t4001 to use modern syntax.
2:  0fec9484a6 < -:  ---------- Update t4009 to use modern style.
3:  4dbb726578 < -:  ---------- Update t4010 to use modern style.
-:  ---------- > 1:  d560c2a155 Update t4001 to use modern syntax.
-:  ---------- > 2:  a52bf71409 Update t4009 to use modern style.
-:  ---------- > 3:  553fe00594 Update t4010 to use modern style.

---
base-commit: 5c40f33ab5825c90dd32cfb08198de2beedc6ed1
change-id: 20260908-modernize-t4001-fb43302caaf9

