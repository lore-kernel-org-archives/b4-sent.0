From: "Mark C. Chu-Carroll" <markchucarroll@fastmail.com>
Subject: [PATCH 0/2] Update tests to use semantic functions
Date: Fri, 04 Sep 2026 16:35:51 -0400
Message-Id: <20260904-file-tests-use-shell-functions-v1-0-b66f9cb4adbe@fastmail.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/yXNwQrCMBCE4Vcpe3YhliagryIeNJm0KyFKNhGh9
 N2N9vgd5p+VFEWgdB5WKniLyjN3HA8D+eWWZ7CEbhrN6MzJTBwlgSu0KjcF64KUOLbsa18qwwT
 n7WSDdZ565FUQ5fM/uFx3a7s/4OuvStv2BXMXTYyCAAAA
X-Change-ID: 20260904-file-tests-use-shell-functions-e0d6c545d56c
To: git@vger.kernel.org
Cc: "Mark C. Chu-Carroll" <markchucarroll@fastmail.com>
X-Mailer: b4 0.16.0
X-Developer-Signature: v=1; a=openpgp-sha256; l=3800;
 i=markchucarroll@fastmail.com; h=from:subject:message-id;
 bh=G1J9z1l3cMiNxee29mdtRcU82QSFZ4+kwd3igm9S4C8=;
 b=owGbwMvMwCUWOPFJle/8tn2Mp9WSGLJma6+pUFtxtYkhoMx2LUN7woyUeWrNylL9s8X6UjoNm
 fi+1ER3lLIwiHExyIopsvz/J9D4iuWBhF/Qu08wc1iZQIYwcHEKwETOrmD4H7ah7OJMjrBXFyqy
 Ez7suPfjZ2nbtrniRU05WwTaGOef5GT4Z+Px7fLN0t1n/EVM+wRSZJ/Yl/bFnu9wqFl68Ahf6it
 nDgA=
X-Developer-Key: i=markchucarroll@fastmail.com; a=openpgp;
 fpr=FFFE1081EA04E0184E52EEF25191E47A4D9F86BE
X-Endpoint-Received: by B4 Relay for markchucarroll@fastmail.com/default with auth_id=1002
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Update tests to use semantic functions like "test_path_is_file"
instead of the older "test -f". All of the tests that make simple
usages are updated; tests that do more complicated things like
starting subshells are left unchanged.

Signed-off-by: Mark C. Chu-Carroll <markchucarroll@fastmail.com>
---
Mark C. Chu-Carroll (2):
      Update shell tests to use semantic functions
      Second batch of shell test migrations.

 t/perf/p5302-pack-index.sh              |  2 +-
 t/t0007-git-var.sh                      |  2 +-
 t/t0031-lockfile-pid.sh                 |  2 +-
 t/t0081-find-pack.sh                    |  2 +-
 t/t0200-gettext-basic.sh                |  2 +-
 t/t1007-hash-object.sh                  |  6 +++---
 t/t1700-split-index.sh                  |  2 +-
 t/t2005-checkout-index-symlinks.sh      |  2 +-
 t/t2030-unresolve-info.sh               |  8 ++++----
 t/t2201-add-update-typechange.sh        |  2 +-
 t/t3300-funny-names.sh                  |  2 +-
 t/t3306-notes-prune.sh                  |  2 +-
 t/t3311-notes-merge-fanout.sh           |  2 +-
 t/t3434-rebase-i18n.sh                  |  2 +-
 t/t3902-quoted.sh                       |  2 +-
 t/t4013-diff-various.sh                 |  2 +-
 t/t4014-format-patch.sh                 |  6 +++---
 t/t4016-diff-quote.sh                   |  2 +-
 t/t4032-diff-inter-hunk-context.sh      |  4 ++--
 t/t4102-apply-rename.sh                 |  2 +-
 t/t4131-apply-fake-ancestor.sh          |  2 +-
 t/t4132-apply-removal.sh                |  4 ++--
 t/t4252-am-options.sh                   |  2 +-
 t/t5000-tar-tree.sh                     |  2 +-
 t/t5100-mailinfo.sh                     |  6 +++---
 t/t5300-pack-object.sh                  | 10 +++++-----
 t/t5301-sliding-window.sh               |  4 ++--
 t/t5302-pack-index.sh                   |  8 ++++----
 t/t5334-incremental-multi-pack-index.sh |  2 +-
 t/t5402-post-merge-hook.sh              |  2 +-
 t/t5500-fetch-pack.sh                   |  2 +-
 t/t5502-quickfetch.sh                   |  2 +-
 t/t5510-fetch.sh                        |  8 ++++----
 t/t5515-fetch-merge-logic.sh            |  4 ++--
 t/t5516-fetch-push.sh                   |  2 +-
 t/t5526-fetch-submodules.sh             |  8 ++++----
 t/t5534-push-signed.sh                  |  6 +++---
 t/t5550-http-fetch-dumb.sh              |  2 +-
 t/t5601-clone.sh                        | 16 ++++++++--------
 t/t5604-clone-reference.sh              |  2 +-
 t/t5702-protocol-v2.sh                  |  4 ++--
 t/t5710-promisor-remote-capability.sh   |  2 +-
 t/t6030-bisect-porcelain.sh             |  2 +-
 t/t6500-gc.sh                           |  2 +-
 t/t7004-tag.sh                          |  4 ++--
 t/t7011-skip-worktree-reading.sh        |  2 +-
 t/t7012-skip-worktree-writing.sh        |  2 +-
 t/t7102-reset.sh                        |  2 +-
 t/t7104-reset-hard.sh                   |  2 +-
 t/t7113-post-index-change-hook.sh       | 12 ++++++------
 t/t7201-co.sh                           |  6 +++---
 t/t7400-submodule-basic.sh              | 10 +++++-----
 t/t7407-submodule-foreach.sh            |  6 +++---
 t/t7409-submodule-detached-work-tree.sh |  2 +-
 t/t7412-submodule-absorbgitdirs.sh      |  8 ++++----
 t/t7450-bad-git-dotfiles.sh             |  6 +++---
 t/t7602-merge-octopus-many.sh           |  2 +-
 t/t7606-merge-custom.sh                 |  8 ++++----
 t/t7610-mergetool.sh                    |  6 +++---
 t/t9400-git-cvsserver-server.sh         |  6 +++---
 t/t9804-git-p4-label.sh                 |  8 ++++----
 61 files changed, 126 insertions(+), 126 deletions(-)


---
base-commit: 2c3adbb2c475981e340c79fdc5e7f4f9b5d9054e
change-id: 20260904-file-tests-use-shell-functions-e0d6c545d56c

