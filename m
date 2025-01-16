From: Karthik Nayak <karthik.188@gmail.com>
Date: Thu, 16 Jan 2025 12:35:16 +0100
Subject: [PATCH 4/5] pack-write: pass hash_algo to `write_rev_file()`
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20250116-kn-the-repo-cleanup-v1-4-a2f4c8e1c4c3@gmail.com>
References: <20250116-kn-the-repo-cleanup-v1-0-a2f4c8e1c4c3@gmail.com>
In-Reply-To: <20250116-kn-the-repo-cleanup-v1-0-a2f4c8e1c4c3@gmail.com>
To: git@vger.kernel.org
Cc: Karthik Nayak <karthik.188@gmail.com>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=openpgp-sha256; l=5880; i=karthik.188@gmail.com;
 h=from:subject:message-id; bh=tgeOZNYzqhCrj1kyCoBVrPtA9tcVhEVzf9gEDPX9KKI=;
 b=owJ4nAHtARL+kA0DAAoBPtWfJI5GjH8ByyZiAGeI7vWaT6EwM4hufwx0JjDEsr2xIujjt8ATv
 vg7jEynvOt7IokBswQAAQoAHRYhBFfOTH9jdXEPy2XGBj7VnySORox/BQJniO71AAoJED7VnySO
 Rox/JGIMAJQOMnZhWPudB1/n0DHvgTNGsGIJPzxpb/Nnl+A24ljgp7nw4VU5PQnT9U5jpHv9cAK
 IRh93WxpH7DzU14nU/QQR7ydfZsUZw2jlRu9lZ9bxTkoZK+PBbZCqTUv17epfCT/6uGXq3P9ZE5
 nkJG95f2i7w+AmRiaD7q9p1Zq/bggRP1jTID15CZPpFp5e4d8IMN9fe47gC5y9ySu6s2/FPk4eA
 6Ah9A/NpuU7h6r1m0hThpacO7wg20kkvYe9zzJBW3XnLc2dtUrUqXEMIn7ayl18rg45N17nyMvg
 g//Xe2uG6nJA4kivfqNm5aKDIZiWZ7p8VdrTpu/t6U+zmX615ICcVUA4JMalca3VOrT/e6mkLDR
 neJYYWR9ORyO6CjJy3tOy6t2IrudHgLwPGaiSyvfzWGXJ9mPhJUhSRdS0JkrG42qnsNH4AVaFZQ
 LNXUSiF7JUPodrGV2/IpiOF8CVtgRkv9/y8aFqvEJg0LsA3cKgvLsSFqEwlidTNu5SVQrwA4nT8
 AQ=
X-Developer-Key: i=karthik.188@gmail.com; a=openpgp;
 fpr=57CE4C7F6375710FCB65C6063ED59F248E468C7F
X-Endpoint-Received: by B4 Relay for karthik.188@gmail.com/default with auth_id=276
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The `write_rev_file()` function uses the global `the_hash_algo` variable
to access the repository's hash function. To avoid global variable
usage, let's pass the hash function from the layers above.

Altough the layers above could have access to the hash function
internally, simply pass in `the_hash_algo`. This avoids any
compatibility issues and bubbles up global variable usage to upper
layers which can be eventually resolved.

However, in `midx-write.c`, since all usage of global variables is
removed, don't reintroduce them and instead use the `repo` available in
the context.

Signed-off-by: Karthik Nayak <karthik.188@gmail.com>
---
 builtin/index-pack.c |  6 +++---
 midx-write.c         |  4 ++--
 pack-write.c         | 21 ++++++++++++---------
 pack.h               | 14 ++++++++++++--
 4 files changed, 29 insertions(+), 16 deletions(-)

diff --git a/builtin/index-pack.c b/builtin/index-pack.c
index d73699653a2227f8ecfee2c0f51cd680093ac764..e803cb2444633f937fafc841848dae85341475f1 100644
--- a/builtin/index-pack.c
+++ b/builtin/index-pack.c
@@ -2099,9 +2099,9 @@ int cmd_index_pack(int argc,
 	curr_index = write_idx_file(the_hash_algo, index_name, idx_objects,
 				    nr_objects, &opts, pack_hash);
 	if (rev_index)
-		curr_rev_index = write_rev_file(rev_index_name, idx_objects,
-						nr_objects, pack_hash,
-						opts.flags);
+		curr_rev_index = write_rev_file(the_hash_algo, rev_index_name,
+						idx_objects, nr_objects,
+						pack_hash, opts.flags);
 	free(idx_objects);
 
 	if (!verify)
diff --git a/midx-write.c b/midx-write.c
index b3827b936bdb1df12c73fb7d9b98ff65fc875cc3..61b59d557d3ba46a39db74c62393545cabf50f2c 100644
--- a/midx-write.c
+++ b/midx-write.c
@@ -658,8 +658,8 @@ static void write_midx_reverse_index(char *midx_name, unsigned char *midx_hash,
 	strbuf_addf(&buf, "%s-%s.rev", midx_name, hash_to_hex_algop(midx_hash,
 								    ctx->repo->hash_algo));
 
-	tmp_file = write_rev_file_order(NULL, ctx->pack_order, ctx->entries_nr,
-					midx_hash, WRITE_REV);
+	tmp_file = write_rev_file_order(ctx->repo->hash_algo, NULL, ctx->pack_order,
+					ctx->entries_nr, midx_hash, WRITE_REV);
 
 	if (finalize_object_file(tmp_file, buf.buf))
 		die(_("cannot store reverse index file"));
diff --git a/pack-write.c b/pack-write.c
index f344e78a9ec20cea9812a5eaffc72ae0b7e7424d..09ecbcdb069cc9b0383295798ceb49cbdc632b64 100644
--- a/pack-write.c
+++ b/pack-write.c
@@ -194,11 +194,12 @@ static int pack_order_cmp(const void *va, const void *vb, void *ctx)
 	return 0;
 }
 
-static void write_rev_header(struct hashfile *f)
+static void write_rev_header(const struct git_hash_algo *hash_algo,
+			     struct hashfile *f)
 {
 	hashwrite_be32(f, RIDX_SIGNATURE);
 	hashwrite_be32(f, RIDX_VERSION);
-	hashwrite_be32(f, oid_version(the_hash_algo));
+	hashwrite_be32(f, oid_version(hash_algo));
 }
 
 static void write_rev_index_positions(struct hashfile *f,
@@ -215,7 +216,8 @@ static void write_rev_trailer(struct hashfile *f, const unsigned char *hash)
 	hashwrite(f, hash, the_hash_algo->rawsz);
 }
 
-char *write_rev_file(const char *rev_name,
+char *write_rev_file(const struct git_hash_algo *hash_algo,
+		     const char *rev_name,
 		     struct pack_idx_entry **objects,
 		     uint32_t nr_objects,
 		     const unsigned char *hash,
@@ -233,15 +235,16 @@ char *write_rev_file(const char *rev_name,
 		pack_order[i] = i;
 	QSORT_S(pack_order, nr_objects, pack_order_cmp, objects);
 
-	ret = write_rev_file_order(rev_name, pack_order, nr_objects, hash,
-				   flags);
+	ret = write_rev_file_order(hash_algo, rev_name, pack_order, nr_objects,
+				   hash, flags);
 
 	free(pack_order);
 
 	return ret;
 }
 
-char *write_rev_file_order(const char *rev_name,
+char *write_rev_file_order(const struct git_hash_algo *hash_algo,
+			   const char *rev_name,
 			   uint32_t *pack_order,
 			   uint32_t nr_objects,
 			   const unsigned char *hash,
@@ -280,7 +283,7 @@ char *write_rev_file_order(const char *rev_name,
 		return NULL;
 	}
 
-	write_rev_header(f);
+	write_rev_header(hash_algo, f);
 
 	write_rev_index_positions(f, pack_order, nr_objects);
 	write_rev_trailer(f, hash);
@@ -568,8 +571,8 @@ void stage_tmp_packfiles(const struct git_hash_algo *hash_algo,
 	if (adjust_shared_perm(*idx_tmp_name))
 		die_errno("unable to make temporary index file readable");
 
-	rev_tmp_name = write_rev_file(NULL, written_list, nr_written, hash,
-				      pack_idx_opts->flags);
+	rev_tmp_name = write_rev_file(hash_algo, NULL, written_list, nr_written,
+				      hash, pack_idx_opts->flags);
 
 	if (pack_idx_opts->flags & WRITE_MTIMES) {
 		mtimes_tmp_name = write_mtimes_file(to_pack, written_list,
diff --git a/pack.h b/pack.h
index c650fdbe2dcde8055ad0efe55646338cd0f81df5..8a84ea475cda902936ee0b6091c5b4d462606be8 100644
--- a/pack.h
+++ b/pack.h
@@ -105,8 +105,18 @@ struct ref;
 
 void write_promisor_file(const char *promisor_name, struct ref **sought, int nr_sought);
 
-char *write_rev_file(const char *rev_name, struct pack_idx_entry **objects, uint32_t nr_objects, const unsigned char *hash, unsigned flags);
-char *write_rev_file_order(const char *rev_name, uint32_t *pack_order, uint32_t nr_objects, const unsigned char *hash, unsigned flags);
+char *write_rev_file(const struct git_hash_algo *hash_algo,
+		     const char *rev_name,
+		     struct pack_idx_entry **objects,
+		     uint32_t nr_objects,
+		     const unsigned char *hash,
+		     unsigned flags);
+char *write_rev_file_order(const struct git_hash_algo *hash_algo,
+			   const char *rev_name,
+			   uint32_t *pack_order,
+			   uint32_t nr_objects,
+			   const unsigned char *hash,
+			   unsigned flags);
 
 /*
  * The "hdr" output buffer should be at least this big, which will handle sizes

-- 
2.47.0

