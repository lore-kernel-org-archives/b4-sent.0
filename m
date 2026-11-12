From: Florian Bauckholt <florian.bauckholt@cispa.de>
Date: Thu, 12 Nov 2026 11:47:57 +0100
Subject: [PATCH] crypto: ecdsa - Reject non-DER X9.62 signatures
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261112-ecdsa-x962-der-v1-1-36b24c5f5e11@cispa.de>
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/yXMMQ6DMAxA0asgz1jCVkGEq1QMIXFbd4AqhgoJc
 XcCjG/4fwOTpGLQFRsk+avpNGZQWUD4+PEtqDEbuOKGqKpRQjSPq2sYoyR04cHkB26pdZCjX5K
 Xrtfw2d+2ZfhKmM8L7PsBwQHgpXIAAAA=
X-Change-ID: 20261105-ecdsa-x962-der-9c421ab28189
To: Lukas Wunner <lukas@wunner.de>, Ignat Korchagin <ignat@linux.win>, 
 Stefan Berger <stefanb@linux.ibm.com>, 
 Herbert Xu <herbert@gondor.apana.org.au>, 
 "David S. Miller" <davem@davemloft.net>
Cc: linux-crypto@vger.kernel.org, keyrings@vger.kernel.org, 
 linux-kernel@vger.kernel.org, 
 Florian Bauckholt <florian.bauckholt@cispa.de>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1794480496; l=13048;
 i=florian.bauckholt@cispa.de; s=20261105; h=from:subject:message-id;
 bh=yTkQrufa4xg5Eamn53YrXpXal0r5XiragW70Vb5FGhM=;
 b=JriJ/+hpO8JTKx/qYNQnlcYeDQ0BxflO73rr9B6SKcOBZHcwQv5ScbSUY/sy6E9hU5/YnX4L5
 Z6TDNkOP20nCtPeHYeIanCK5FfQWg4HwJ8PlwIhPace2bEcJWu41bBh
X-Developer-Key: i=florian.bauckholt@cispa.de; a=ed25519;
 pk=n9klXQ+dI45FWy0qWLrGpQfXU5ylIA0SN+uWSmOx3ok=
X-Endpoint-Received: by B4 Relay for florian.bauckholt@cispa.de/20261105 with auth_id=1420
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The x962(ecdsa-nist-*) template decodes Ecdsa-Sig-Value with the
generic BER decoder, and ecdsa_get_signature_rs() only strips one
leading zero byte without looking at the INTEGER's sign or encoding.
As a result the following encodings of a valid signature are accepted
as well:

 - a SEQUENCE tag without the constructed bit (0x10 instead of 0x30),
   as the decoder ignores that bit when matching a constructed tag
 - non-minimal length encodings of the SEQUENCE, r or s (long form
   where the short form fits, or padded with zero bytes)
 - indefinite length for the SEQUENCE
 - data following the SEQUENCE (the decoder does not check that the
   whole buffer was consumed)
 - r or s with the most significant bit set but without the leading
   zero byte, i.e. a negative INTEGER read as positive
 - r or s with a superfluous leading zero byte

RFC 3279 section 2.2.3 and SEC 1 section C.5 require Ecdsa-Sig-Value to
be DER-encoded, so all of these are invalid and should be rejected.

This is a behaviour change for every user of the x962 template (X.509
certificates, module and IMA signatures, KEYCTL_PKEY_VERIFY): signatures
that are valid ECDSA signatures but are not DER-encoded used to verify
and are now rejected with -EINVAL. The p1363 template is not affected.

Add a test vector for each of these encodings, taken or derived from
Wycheproof's secp256r1/SHA-256 test vectors.

Found by differential testing against other ECDSA implementations.

Fixes: 4e6602916bc6 ("crypto: ecdsa - Add support for ECDSA signature verification")
Signed-off-by: Florian Bauckholt <florian.bauckholt@cispa.de>
---
Hi,

I recently tried out differential testing for crypto libraries and ran
into a DER-vs-BER discrepancy after hooking up Linux's x962
implementation via UML. I don't see a security impact: the signature
must still be valid for the key, only its encoding is malleable. But all
major implementations reject BER encodings for x962.

The patch works around the fact that the ASN.1 input is parsed by a
generic BER parser by checking each potential difference between DER and
BER. This is the minimal change, but a more generic "strict DER parser"
might be a better solution imo. Should the ASN.1 decoder instead learn
an opt-in strict mode?

One dependency: since commit cb481e59ea6c ("KEYS: fix overflow in
keyctl_pkey_params_get_2()") KEYCTL_PKEY_VERIFY passes max_sig_size
instead of the caller's signature length, so the signature handed to
the x962 template is followed by trailing bytes whenever it is shorter
than the maximum. That only works today because the BER decoder ignores
trailing data. With this patch such signatures are rejected via keyctl.
The fix for that is patch 1/2 of the series below, posted separately to
the keyrings list, and should go in first:

  https://lore.kernel.org/r/20261111-keyctl-pkey-fixes-v1-0-934ebaa267a7@cispa.de

I did not add Cc: stable since this is a behaviour change. If you would
like it backported, note that v7.2 and later need the keyctl fix first.

Tool-generated content: I used LLMs (Claude) to implement and iterate on
the patch. I'm fairly confident the fix is complete because it passes
differential testing.

Thanks!
---
 crypto/ecdsa-x962.c |  36 ++++++++++++
 crypto/testmgr.h    | 161 ++++++++++++++++++++++++++++++++++++++++++++++++++++
 2 files changed, 197 insertions(+)

diff --git a/crypto/ecdsa-x962.c b/crypto/ecdsa-x962.c
index ee71594d10a0..69e932bbd551 100644
--- a/crypto/ecdsa-x962.c
+++ b/crypto/ecdsa-x962.c
@@ -6,6 +6,7 @@
  * Copyright (c) 2024 Intel Corporation
  */
 
+#include <linux/asn1.h>
 #include <linux/asn1_decoder.h>
 #include <linux/err.h>
 #include <linux/module.h>
@@ -36,6 +37,20 @@ static int ecdsa_get_signature_rs(u64 *dest, size_t hdrlen, unsigned char tag,
 	if (!value || !vlen || vlen > bufsize + 1)
 		return -EINVAL;
 
+	/*
+	 * The signature must be DER-encoded (RFC 3279 section 2.2.3, SEC 1
+	 * section C.5): an INTEGER with a short-form length (vlen never
+	 * exceeds 127 bytes) and minimal two's complement contents that
+	 * encode a non-negative value (X.690 sections 8.3.2 and 10.1).  The
+	 * decoder has already matched the primitive INTEGER tag exactly.
+	 */
+	if (hdrlen != 2)
+		return -EINVAL;
+	if (d[0] & 0x80)
+		return -EINVAL;
+	if (vlen > 1 && d[0] == 0 && !(d[1] & 0x80))
+		return -EINVAL;
+
 	/*
 	 * vlen may be 1 byte larger than bufsize due to a leading zero byte
 	 * (necessary if the most significant bit of the integer is set).
@@ -73,6 +88,24 @@ int ecdsa_get_signature_s(void *context, size_t hdrlen, unsigned char tag,
 				      sig_ctx->ndigits);
 }
 
+/*
+ * The BER decoder accepts a SEQUENCE tag without the constructed bit,
+ * long-form and indefinite lengths, and ignores data following the SEQUENCE.
+ * DER permits only the constructed tag, the shortest length encoding and
+ * nothing after the SEQUENCE.  The decoder has already checked that r and s
+ * fill a definite-length SEQUENCE exactly.
+ */
+static bool ecdsa_x962_seq_is_der(const u8 *src, unsigned int slen)
+{
+	if (src[0] != (ASN1_CONS_BIT | ASN1_SEQ))
+		return false;
+
+	if (src[1] < 0x80)
+		return slen == 2 + src[1];
+
+	return src[1] == 0x81 && src[2] >= 0x80 && slen == 3 + src[2];
+}
+
 static int ecdsa_x962_verify(struct crypto_sig *tfm,
 			     const void *src, unsigned int slen,
 			     const void *digest, unsigned int dlen)
@@ -88,6 +121,9 @@ static int ecdsa_x962_verify(struct crypto_sig *tfm,
 	if (err < 0)
 		return err;
 
+	if (!ecdsa_x962_seq_is_der(src, slen))
+		return -EINVAL;
+
 	return crypto_sig_verify(ctx->child, &sig_ctx.sig, sizeof(sig_ctx.sig),
 				 digest, dlen);
 }
diff --git a/crypto/testmgr.h b/crypto/testmgr.h
index 0ee15a8fae27..635032615212 100644
--- a/crypto/testmgr.h
+++ b/crypto/testmgr.h
@@ -1490,6 +1490,167 @@ static const struct sig_testvec x962_ecdsa_nist_p256_tv_template[] = {
 	.verify_error = -EKEYREJECTED,
 	.public_key_vec = true,
 	},
+	/* Wycheproof secp256r1/SHA-256 tcId 6: negative s. */
+	{
+	.key =
+	"\x04\x29\x27\xb1\x05\x12\xba\xe3\xed\xdc\xfe\x46\x78\x28\x12\x8b"
+	"\xad\x29\x03\x26\x99\x19\xf7\x08\x60\x69\xc8\xc4\xdf\x6c\x73\x28"
+	"\x38\xc7\x78\x79\x64\xea\xac\x00\xe5\x92\x1f\xb1\x49\x8a\x60\xf4"
+	"\x60\x67\x66\xb3\xd9\x68\x50\x01\x55\x8d\x1a\x97\x4e\x73\x41\x51"
+	"\x3e",
+	.key_len = 65,
+	.m =
+	"\xbb\x5a\x52\xf4\x2f\x9c\x92\x61\xed\x43\x61\xf5\x94\x22\xa1\xe3"
+	"\x00\x36\xe7\xc3\x2b\x27\x0c\x88\x07\xa4\x19\xfe\xca\x60\x50\x23",
+	.m_size = 32,
+	.c =
+	"\x30\x44\x02\x20\x2b\xa3\xa8\xbe\x6b\x94\xd5\xec\x80\xa6\xd9\xd1"
+	"\x19\x0a\x43\x6e\xff\xe5\x0d\x85\xa1\xee\xe8\x59\xb8\xcc\x6a\xf9"
+	"\xbd\x5c\x2e\x18\x02\x20\xb3\x29\xf4\x79\xa2\xbb\xd0\xa5\xc3\x84"
+	"\xee\x14\x93\xb1\xf5\x18\x6a\x87\x13\x9c\xac\x5d\xf4\x08\x7c\x13"
+	"\x4b\x49\x15\x68\x47\xdb",
+	.c_size = 70,
+	.verify_error = -EINVAL,
+	.public_key_vec = true,
+	},
+	/* Wycheproof secp256r1/SHA-256 tcId 8: long-form length. */
+	{
+	.key =
+	"\x04\x29\x27\xb1\x05\x12\xba\xe3\xed\xdc\xfe\x46\x78\x28\x12\x8b"
+	"\xad\x29\x03\x26\x99\x19\xf7\x08\x60\x69\xc8\xc4\xdf\x6c\x73\x28"
+	"\x38\xc7\x78\x79\x64\xea\xac\x00\xe5\x92\x1f\xb1\x49\x8a\x60\xf4"
+	"\x60\x67\x66\xb3\xd9\x68\x50\x01\x55\x8d\x1a\x97\x4e\x73\x41\x51"
+	"\x3e",
+	.key_len = 65,
+	.m =
+	"\xbb\x5a\x52\xf4\x2f\x9c\x92\x61\xed\x43\x61\xf5\x94\x22\xa1\xe3"
+	"\x00\x36\xe7\xc3\x2b\x27\x0c\x88\x07\xa4\x19\xfe\xca\x60\x50\x23",
+	.m_size = 32,
+	.c =
+	"\x30\x81\x45\x02\x20\x2b\xa3\xa8\xbe\x6b\x94\xd5\xec\x80\xa6\xd9"
+	"\xd1\x19\x0a\x43\x6e\xff\xe5\x0d\x85\xa1\xee\xe8\x59\xb8\xcc\x6a"
+	"\xf9\xbd\x5c\x2e\x18\x02\x21\x00\xb3\x29\xf4\x79\xa2\xbb\xd0\xa5"
+	"\xc3\x84\xee\x14\x93\xb1\xf5\x18\x6a\x87\x13\x9c\xac\x5d\xf4\x08"
+	"\x7c\x13\x4b\x49\x15\x68\x47\xdb",
+	.c_size = 72,
+	.verify_error = -EINVAL,
+	.public_key_vec = true,
+	},
+	/* Wycheproof secp256r1/SHA-256 tcId 25: data after the SEQUENCE. */
+	{
+	.key =
+	"\x04\x29\x27\xb1\x05\x12\xba\xe3\xed\xdc\xfe\x46\x78\x28\x12\x8b"
+	"\xad\x29\x03\x26\x99\x19\xf7\x08\x60\x69\xc8\xc4\xdf\x6c\x73\x28"
+	"\x38\xc7\x78\x79\x64\xea\xac\x00\xe5\x92\x1f\xb1\x49\x8a\x60\xf4"
+	"\x60\x67\x66\xb3\xd9\x68\x50\x01\x55\x8d\x1a\x97\x4e\x73\x41\x51"
+	"\x3e",
+	.key_len = 65,
+	.m =
+	"\xbb\x5a\x52\xf4\x2f\x9c\x92\x61\xed\x43\x61\xf5\x94\x22\xa1\xe3"
+	"\x00\x36\xe7\xc3\x2b\x27\x0c\x88\x07\xa4\x19\xfe\xca\x60\x50\x23",
+	.m_size = 32,
+	.c =
+	"\x30\x45\x02\x20\x2b\xa3\xa8\xbe\x6b\x94\xd5\xec\x80\xa6\xd9\xd1"
+	"\x19\x0a\x43\x6e\xff\xe5\x0d\x85\xa1\xee\xe8\x59\xb8\xcc\x6a\xf9"
+	"\xbd\x5c\x2e\x18\x02\x21\x00\xb3\x29\xf4\x79\xa2\xbb\xd0\xa5\xc3"
+	"\x84\xee\x14\x93\xb1\xf5\x18\x6a\x87\x13\x9c\xac\x5d\xf4\x08\x7c"
+	"\x13\x4b\x49\x15\x68\x47\xdb\x00\x00",
+	.c_size = 73,
+	.verify_error = -EINVAL,
+	.public_key_vec = true,
+	},
+	/* Wycheproof secp256r1/SHA-256 tcId 48: indefinite length. */
+	{
+	.key =
+	"\x04\x29\x27\xb1\x05\x12\xba\xe3\xed\xdc\xfe\x46\x78\x28\x12\x8b"
+	"\xad\x29\x03\x26\x99\x19\xf7\x08\x60\x69\xc8\xc4\xdf\x6c\x73\x28"
+	"\x38\xc7\x78\x79\x64\xea\xac\x00\xe5\x92\x1f\xb1\x49\x8a\x60\xf4"
+	"\x60\x67\x66\xb3\xd9\x68\x50\x01\x55\x8d\x1a\x97\x4e\x73\x41\x51"
+	"\x3e",
+	.key_len = 65,
+	.m =
+	"\xbb\x5a\x52\xf4\x2f\x9c\x92\x61\xed\x43\x61\xf5\x94\x22\xa1\xe3"
+	"\x00\x36\xe7\xc3\x2b\x27\x0c\x88\x07\xa4\x19\xfe\xca\x60\x50\x23",
+	.m_size = 32,
+	.c =
+	"\x30\x80\x02\x20\x2b\xa3\xa8\xbe\x6b\x94\xd5\xec\x80\xa6\xd9\xd1"
+	"\x19\x0a\x43\x6e\xff\xe5\x0d\x85\xa1\xee\xe8\x59\xb8\xcc\x6a\xf9"
+	"\xbd\x5c\x2e\x18\x02\x21\x00\xb3\x29\xf4\x79\xa2\xbb\xd0\xa5\xc3"
+	"\x84\xee\x14\x93\xb1\xf5\x18\x6a\x87\x13\x9c\xac\x5d\xf4\x08\x7c"
+	"\x13\x4b\x49\x15\x68\x47\xdb\x00\x00",
+	.c_size = 73,
+	.verify_error = -EINVAL,
+	.public_key_vec = true,
+	},
+	/* Wycheproof secp256r1/SHA-256 tcId 5 with a primitive SEQUENCE tag. */
+	{
+	.key =
+	"\x04\x29\x27\xb1\x05\x12\xba\xe3\xed\xdc\xfe\x46\x78\x28\x12\x8b"
+	"\xad\x29\x03\x26\x99\x19\xf7\x08\x60\x69\xc8\xc4\xdf\x6c\x73\x28"
+	"\x38\xc7\x78\x79\x64\xea\xac\x00\xe5\x92\x1f\xb1\x49\x8a\x60\xf4"
+	"\x60\x67\x66\xb3\xd9\x68\x50\x01\x55\x8d\x1a\x97\x4e\x73\x41\x51"
+	"\x3e",
+	.key_len = 65,
+	.m =
+	"\xbb\x5a\x52\xf4\x2f\x9c\x92\x61\xed\x43\x61\xf5\x94\x22\xa1\xe3"
+	"\x00\x36\xe7\xc3\x2b\x27\x0c\x88\x07\xa4\x19\xfe\xca\x60\x50\x23",
+	.m_size = 32,
+	.c =
+	"\x10\x44\x02\x20\x2b\xa3\xa8\xbe\x6b\x94\xd5\xec\x80\xa6\xd9\xd1"
+	"\x19\x0a\x43\x6e\xff\xe5\x0d\x85\xa1\xee\xe8\x59\xb8\xcc\x6a\xf9"
+	"\xbd\x5c\x2e\x18\x02\x20\x4c\xd6\x0b\x85\x5d\x44\x2f\x5b\x3c\x7b"
+	"\x11\xeb\x6c\x4e\x0a\xe7\x52\x5f\xe7\x10\xfa\xb9\xaa\x7c\x77\xa6"
+	"\x7f\x79\xe6\xfa\xdd\x76",
+	.c_size = 70,
+	.verify_error = -EINVAL,
+	.public_key_vec = true,
+	},
+	/* Wycheproof secp256r1/SHA-256 tcId 5 with a superfluous zero in r. */
+	{
+	.key =
+	"\x04\x29\x27\xb1\x05\x12\xba\xe3\xed\xdc\xfe\x46\x78\x28\x12\x8b"
+	"\xad\x29\x03\x26\x99\x19\xf7\x08\x60\x69\xc8\xc4\xdf\x6c\x73\x28"
+	"\x38\xc7\x78\x79\x64\xea\xac\x00\xe5\x92\x1f\xb1\x49\x8a\x60\xf4"
+	"\x60\x67\x66\xb3\xd9\x68\x50\x01\x55\x8d\x1a\x97\x4e\x73\x41\x51"
+	"\x3e",
+	.key_len = 65,
+	.m =
+	"\xbb\x5a\x52\xf4\x2f\x9c\x92\x61\xed\x43\x61\xf5\x94\x22\xa1\xe3"
+	"\x00\x36\xe7\xc3\x2b\x27\x0c\x88\x07\xa4\x19\xfe\xca\x60\x50\x23",
+	.m_size = 32,
+	.c =
+	"\x30\x45\x02\x21\x00\x2b\xa3\xa8\xbe\x6b\x94\xd5\xec\x80\xa6\xd9"
+	"\xd1\x19\x0a\x43\x6e\xff\xe5\x0d\x85\xa1\xee\xe8\x59\xb8\xcc\x6a"
+	"\xf9\xbd\x5c\x2e\x18\x02\x20\x4c\xd6\x0b\x85\x5d\x44\x2f\x5b\x3c"
+	"\x7b\x11\xeb\x6c\x4e\x0a\xe7\x52\x5f\xe7\x10\xfa\xb9\xaa\x7c\x77"
+	"\xa6\x7f\x79\xe6\xfa\xdd\x76",
+	.c_size = 71,
+	.verify_error = -EINVAL,
+	.public_key_vec = true,
+	},
+	/* Wycheproof secp256r1/SHA-256 tcId 5 with a long-form length of r. */
+	{
+	.key =
+	"\x04\x29\x27\xb1\x05\x12\xba\xe3\xed\xdc\xfe\x46\x78\x28\x12\x8b"
+	"\xad\x29\x03\x26\x99\x19\xf7\x08\x60\x69\xc8\xc4\xdf\x6c\x73\x28"
+	"\x38\xc7\x78\x79\x64\xea\xac\x00\xe5\x92\x1f\xb1\x49\x8a\x60\xf4"
+	"\x60\x67\x66\xb3\xd9\x68\x50\x01\x55\x8d\x1a\x97\x4e\x73\x41\x51"
+	"\x3e",
+	.key_len = 65,
+	.m =
+	"\xbb\x5a\x52\xf4\x2f\x9c\x92\x61\xed\x43\x61\xf5\x94\x22\xa1\xe3"
+	"\x00\x36\xe7\xc3\x2b\x27\x0c\x88\x07\xa4\x19\xfe\xca\x60\x50\x23",
+	.m_size = 32,
+	.c =
+	"\x30\x45\x02\x81\x20\x2b\xa3\xa8\xbe\x6b\x94\xd5\xec\x80\xa6\xd9"
+	"\xd1\x19\x0a\x43\x6e\xff\xe5\x0d\x85\xa1\xee\xe8\x59\xb8\xcc\x6a"
+	"\xf9\xbd\x5c\x2e\x18\x02\x20\x4c\xd6\x0b\x85\x5d\x44\x2f\x5b\x3c"
+	"\x7b\x11\xeb\x6c\x4e\x0a\xe7\x52\x5f\xe7\x10\xfa\xb9\xaa\x7c\x77"
+	"\xa6\x7f\x79\xe6\xfa\xdd\x76",
+	.c_size = 71,
+	.verify_error = -EINVAL,
+	.public_key_vec = true,
+	},
 	/* Wycheproof secp256r1/SHA-256 tcId 60. */
 	{
 	.key =

---
base-commit: 6628e7d4c6b25c8d18f1345e3a20d21829aae7e4
change-id: 20261105-ecdsa-x962-der-9c421ab28189

Best regards,
--  
Florian Bauckholt <florian.bauckholt@cispa.de>

