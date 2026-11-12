From: Yusuke Hayashi <yusuke8h@gmail.com>
Date: Thu, 12 Nov 2026 05:57:35 +0000
Subject: [PATCH] refs: drop unused `peel_iterated_oid()` declaration
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261112-refs-drop-peel-iterated-oid-v1-1-7df1c313e293@gmail.com>
X-B4-Tracking: v=1; b=H4sIAE5V9WoC/yXMQQrCMBBG4auUWTvQCSjoVcRFzPzVEWlCJopQe
 ndjXX7weAs5qsHpNCxU8Ta3PHfIbqB0j/MNbNpNYQwHEQlcMTlrzYUL8GRrqLFBOZsyFOE4CiT
 tI/VD6bF9tvv58re/rg+k9lvSun4But0yAX8AAAA=
X-Change-ID: 20261112-refs-drop-peel-iterated-oid-ede2901e1c5a
To: git@vger.kernel.org
Cc: Patrick Steinhardt <ps@pks.im>, Karthik Nayak <karthik.188@gmail.com>, 
 Yusuke Hayashi <yusuke8h@gmail.com>
X-Mailer: b4 0.16.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1794463058; l=1405;
 i=yusuke8h@gmail.com; s=20261112; h=from:subject:message-id;
 bh=dC5up5AgSmgB4z4cviymA6G535FcTBxD4cy7cR+IDW8=;
 b=81zYynGe+1TZePPrjZgJnfxyxZNNTPrub1dBBsheufc1+o9GUrdwT1rsE22qHNqqZ3rP+FBzs
 AJweKuLgQ9ED36U7bW8GPMeC40XMAiH5ACqQB0/ADj5wbqHPGhxOU2j
X-Developer-Key: i=yusuke8h@gmail.com; a=ed25519;
 pk=7SzYbbTWl4u1a0gmKeMxAqo7g7F1K7tnWWGWQ+LnNNs=
X-Endpoint-Received: by B4 Relay for yusuke8h@gmail.com/20261112 with auth_id=1495
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Commit 5a5c7359f7 (refs: drop `current_ref_iter` hack, 2025-10-23)
removed `peel_iterated_oid()` from "refs.c" after converting all of its
callers to `reference_get_peeled_oid()`, leaving behind the declaration
in "refs.h".

Remove the unused declaration and its comment.

Signed-off-by: Yusuke Hayashi <yusuke8h@gmail.com>
---
 refs.h | 13 -------------
 1 file changed, 13 deletions(-)

diff --git a/refs.h b/refs.h
index ee3b8a62ef..73076cba2f 100644
--- a/refs.h
+++ b/refs.h
@@ -178,19 +178,6 @@ void ref_store_release(struct ref_store *ref_store);
  */
 int ref_store_remove_on_disk(struct ref_store *refs, struct strbuf *err);
 
-/*
- * Return the peeled value of the oid currently being iterated via
- * for_each_ref(), etc. This is equivalent to calling:
- *
- *   peel_object(r, oid, &peeled);
- *
- * with the "oid" value given to the refs_for_each_cb callback, except
- * that some ref storage may be able to answer the query without
- * actually loading the object in memory.
- */
-int peel_iterated_oid(struct repository *r,
-		      const struct object_id *base, struct object_id *peeled);
-
 /**
  * Resolve refname in the nested "gitlink" repository in the specified
  * submodule (which must be non-NULL). If the resolution is

---
base-commit: 1891de46f79dc444a47db1c87bd0c8c76b5463f2
change-id: 20261112-refs-drop-peel-iterated-oid-ede2901e1c5a

