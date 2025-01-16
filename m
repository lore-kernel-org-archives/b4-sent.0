From: Karthik Nayak <karthik.188@gmail.com>
Date: Thu, 16 Jan 2025 12:35:17 +0100
Subject: [PATCH 5/5] pack-write: pass hash_algo to `write_rev_*()`
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20250116-kn-the-repo-cleanup-v1-5-a2f4c8e1c4c3@gmail.com>
References: <20250116-kn-the-repo-cleanup-v1-0-a2f4c8e1c4c3@gmail.com>
In-Reply-To: <20250116-kn-the-repo-cleanup-v1-0-a2f4c8e1c4c3@gmail.com>
To: git@vger.kernel.org
Cc: Karthik Nayak <karthik.188@gmail.com>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=openpgp-sha256; l=3538; i=karthik.188@gmail.com;
 h=from:subject:message-id; bh=9apsR1GBlegQZhItb+8Q0LgeChaYi1HyTHkcGvoZGi8=;
 b=owJ4nAHtARL+kA0DAAoBPtWfJI5GjH8ByyZiAGeI7vUQov1ESSA2Ouu5Qn6GmWVnU1BTp16lf
 nN9cCE5ZZWX9YkBswQAAQoAHRYhBFfOTH9jdXEPy2XGBj7VnySORox/BQJniO71AAoJED7VnySO
 Rox/8bcL/jliaQT0LoddbUaadjRZMYklcT9H9GiZzGrsnoPblf9l0Y4ompHH2qY6FUuqPiNr4p5
 r8iHxsAPRsg3fsQoT3cwokR52jcCZ/qfmiYIv9vFNVfuofXuzkpHQ0H0O2G8TVA7XU2gtHBZUpb
 njLo4v3kniTP75iqJ4R7ZwFvDssFatq9OfXHtb6ug75WOlck/DjzEFj4E0tZscoaPo+o9SmAO5b
 LvYSKJaGcMuoeEI7/+rk3zoiw8PWO3/3ELVFVaO7p9d0wmFDewiuzTi/U7hZhF830NM7CcAdqoD
 NCwE71dVo/PnRglkGhe+bnN++pY6sxqgn6iTatKdK9lsGSWJvZj+xBsKudnGoVHP841g+PtEubJ
 wesJ4BQ1HP+F6tJqu+8oM93GeKa2JChdUvFF0i0/ggf8/NAUNa4tGWfV7/vLr49qVepIwsckS/H
 NFMeCN2F4VzqgrPckGbRvHsPFhFO6bC9zBvI1aDcGVNiC+KKGgY3cNF/hQAvVfHnnjwIwG3kH38
 Ak=
X-Developer-Key: i=karthik.188@gmail.com; a=openpgp;
 fpr=57CE4C7F6375710FCB65C6063ED59F248E468C7F
X-Endpoint-Received: by B4 Relay for karthik.188@gmail.com/default with auth_id=276
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The `write_rev_*()` functions use the global `the_hash_algo` variable to
access the repository's hash function. Pass the hash from down as we've
added made them available in the previous few commits.

Signed-off-by: Karthik Nayak <karthik.188@gmail.com>
---
 pack-write.c | 30 ++++++++++++++++--------------
 1 file changed, 16 insertions(+), 14 deletions(-)

diff --git a/pack-write.c b/pack-write.c
index 09ecbcdb069cc9b0383295798ceb49cbdc632b64..a2faeb1895e41f4c17281380478f1f2cabcc6f24 100644
--- a/pack-write.c
+++ b/pack-write.c
@@ -1,5 +1,3 @@
-#define USE_THE_REPOSITORY_VARIABLE
-
 #include "git-compat-util.h"
 #include "environment.h"
 #include "gettext.h"
@@ -211,9 +209,10 @@ static void write_rev_index_positions(struct hashfile *f,
 		hashwrite_be32(f, pack_order[i]);
 }
 
-static void write_rev_trailer(struct hashfile *f, const unsigned char *hash)
+static void write_rev_trailer(const struct git_hash_algo *hash_algo,
+			      struct hashfile *f, const unsigned char *hash)
 {
-	hashwrite(f, hash, the_hash_algo->rawsz);
+	hashwrite(f, hash, hash_algo->rawsz);
 }
 
 char *write_rev_file(const struct git_hash_algo *hash_algo,
@@ -286,7 +285,7 @@ char *write_rev_file_order(const struct git_hash_algo *hash_algo,
 	write_rev_header(hash_algo, f);
 
 	write_rev_index_positions(f, pack_order, nr_objects);
-	write_rev_trailer(f, hash);
+	write_rev_trailer(hash_algo, f, hash);
 
 	if (adjust_shared_perm(path) < 0)
 		die(_("failed to make %s readable"), path);
@@ -298,11 +297,12 @@ char *write_rev_file_order(const struct git_hash_algo *hash_algo,
 	return path;
 }
 
-static void write_mtimes_header(struct hashfile *f)
+static void write_mtimes_header(const struct git_hash_algo *hash_algo,
+				struct hashfile *f)
 {
 	hashwrite_be32(f, MTIMES_SIGNATURE);
 	hashwrite_be32(f, MTIMES_VERSION);
-	hashwrite_be32(f, oid_version(the_hash_algo));
+	hashwrite_be32(f, oid_version(hash_algo));
 }
 
 /*
@@ -322,12 +322,14 @@ static void write_mtimes_objects(struct hashfile *f,
 	}
 }
 
-static void write_mtimes_trailer(struct hashfile *f, const unsigned char *hash)
+static void write_mtimes_trailer(const struct git_hash_algo *hash_algo,
+				 struct hashfile *f, const unsigned char *hash)
 {
-	hashwrite(f, hash, the_hash_algo->rawsz);
+	hashwrite(f, hash, hash_algo->rawsz);
 }
 
-static char *write_mtimes_file(struct packing_data *to_pack,
+static char *write_mtimes_file(const struct git_hash_algo *hash_algo,
+			       struct packing_data *to_pack,
 			       struct pack_idx_entry **objects,
 			       uint32_t nr_objects,
 			       const unsigned char *hash)
@@ -344,9 +346,9 @@ static char *write_mtimes_file(struct packing_data *to_pack,
 	mtimes_name = strbuf_detach(&tmp_file, NULL);
 	f = hashfd(fd, mtimes_name);
 
-	write_mtimes_header(f);
+	write_mtimes_header(hash_algo, f);
 	write_mtimes_objects(f, to_pack, objects, nr_objects);
-	write_mtimes_trailer(f, hash);
+	write_mtimes_trailer(hash_algo, f, hash);
 
 	if (adjust_shared_perm(mtimes_name) < 0)
 		die(_("failed to make %s readable"), mtimes_name);
@@ -575,8 +577,8 @@ void stage_tmp_packfiles(const struct git_hash_algo *hash_algo,
 				      hash, pack_idx_opts->flags);
 
 	if (pack_idx_opts->flags & WRITE_MTIMES) {
-		mtimes_tmp_name = write_mtimes_file(to_pack, written_list,
-						    nr_written,
+		mtimes_tmp_name = write_mtimes_file(hash_algo, to_pack,
+						    written_list, nr_written,
 						    hash);
 	}
 

-- 
2.47.0

