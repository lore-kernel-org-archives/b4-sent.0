From: Mustafa Bayar <mbayar@gitlab.com>
Date: Thu, 12 Nov 2026 10:48:41 +0100
Subject: [PATCH] ref-filter: fix double free when an object is missing
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261112-mb-ref-filter-missing-object-double-free-maint-v1-1-d6d56a3c8dbe@gitlab.com>
X-B4-Tracking: v=1; b=H4sIAAAAAAAA/yWNwQ7CIBAFf6XZs5u4HDT6K8YDlEddU8AANSZN/
 12sxznMzEoVRVHpOqxU8NaqOXWQw0Djw6YJrL4zmaM5iYjh6LggcNC5oXDUWjVNnN0TY2OfFze
 DQwE4Wk2NL7DeBYjgLNSjry7rZx/e7n+uyy7/LrRtX9M8mmCSAAAA
X-Change-ID: 20261112-mb-ref-filter-missing-object-double-free-maint-9eadbfe11e71
To: git@vger.kernel.org
Cc: Patrick Steinhardt <ps@pks.im>, Mustafa Bayar <mbayar@gitlab.com>
X-Mailer: b4 0.16.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1794476930; l=3161;
 i=mbayar@gitlab.com; s=20261112; h=from:subject:message-id;
 bh=17NMEKwQrzxXBwY9i9TNeZiPlUzKGWgLZuhnC15Ryjc=;
 b=iOM2yA0Rlz2Y/aVunYcpa7j2Vu5sBTK24l/YZ3uKX58eHG78qV83Hj3cdIXkn0PKrekuny9/h
 alrxfQt9MgFDeysVvKsLvY8Dj9oiYORmaXLoCuBT0aX1IOBRItMoqAK
X-Developer-Key: i=mbayar@gitlab.com; a=ed25519;
 pk=y0gEEr1TaZuk0b9DG9SOBVMs0YNrf+G51ueJbMsIBCc=
X-Endpoint-Received: by B4 Relay for mbayar@gitlab.com/20261112 with auth_id=1496
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

When a ref points to a missing object, git-for-each-ref(1) may abort
with a double free instead of reporting the missing object:

    free(): double free detected in tcache 2

get_object() frees `oi->content` but leaves the pointer unchanged. Since
the expand_data structures are reused across refs, a later call can
start with `content` pointing to a freed buffer. Then, if the object
lookup in that call fails before it overwrites the pointer, the cleanup
path frees the buffer a second time.

a29e2e8fe (ref-filter: parse objects on demand, 2025-10-23) introduced
this by making object lookup failures jump to the cleanup label.
bea37f1d6 (ref-filter: fix stale parsed objects, 2025-11-04) later fixed
a related stale-state bug by resetting `maybe_object`.

Similar to `maybe_object`, reset `content` at the start of get_object().
Add a regression test that exercises this path.

Signed-off-by: Mustafa Bayar <mbayar@gitlab.com>
---
This is based on maint, since the bug first appeared in v2.53.0.

We ran into this on GitLab.com, where a repository with a tag pointing
to a missing object made `git for-each-ref` abort instead of reporting
the missing object.

A note on the test: the double free only happens when a valid annotated
tag is processed before the broken ref, so that an earlier get_object()
call has already freed its content buffer. The test therefore names the
refs `annotated` and `missing`, which sort in that order.
---
 ref-filter.c                   |  1 +
 t/t6301-for-each-ref-errors.sh | 15 +++++++++++++++
 2 files changed, 16 insertions(+)

diff --git a/ref-filter.c b/ref-filter.c
index bdf54f6f..6c4df521 100644
--- a/ref-filter.c
+++ b/ref-filter.c
@@ -2349,6 +2349,7 @@ static int get_object(struct ref_array_item *ref, int deref,
 	int ret;
 
 	oi->maybe_object = NULL;
+	oi->content = NULL;
 
 	if (oi->info.contentp) {
 		/* We need to know that to use parse_object_buffer properly */
diff --git a/t/t6301-for-each-ref-errors.sh b/t/t6301-for-each-ref-errors.sh
index 72b27c8b..e955f66a 100755
--- a/t/t6301-for-each-ref-errors.sh
+++ b/t/t6301-for-each-ref-errors.sh
@@ -52,6 +52,21 @@ test_expect_success 'Missing objects are reported correctly' '
 	test_must_be_empty brief-err
 '
 
+test_expect_success 'missing objects after a tag are reported correctly' '
+	test_when_finished "rm -rf repo" &&
+	git init repo &&
+	(
+		cd repo &&
+		test_commit --no-tag initial &&
+		git tag -a -m annotated annotated &&
+		test-tool ref-store main update-ref msg refs/tags/missing "$MISSING" "$ZERO_OID" REF_SKIP_OID_VERIFICATION &&
+		git rev-parse HEAD >expect &&
+		test_must_fail git for-each-ref --format="%(*objectname)" refs/tags/ >actual 2>err &&
+		test_cmp expect actual &&
+		test_grep "fatal: missing object $MISSING for refs/tags/missing" err
+	)
+'
+
 test_expect_success 'missing ancestors are reported by contains filters' '
 	test_when_finished "git update-ref -d refs/heads/missing-parent" &&
 	{

---
base-commit: 03b41523c576f26ad34085378717a0c1b287470f
change-id: 20261112-mb-ref-filter-missing-object-double-free-maint-9eadbfe11e71

