From: Alon Shakevsky <shakevsky@berkeley.edu>
Date: Sat, 29 Aug 2026 06:27:46 +0000
Subject: [PATCH] ksmbd: validate normalized name response length
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260829-review-ksmbd-normalized-name-v1-v1-1-4fab73835057@berkeley.edu>
X-B4-Tracking: v=1; b=H4sIAOF7kmoC/yWNQQ6CMBREr0L+2p9AjVa9inHRlql+tYW0CkTC3
 S26m5dM3pspIwkynaqZEgbJ0sUCzaYidzPxCpa2MKla7euDOvJ6wsiPHGzLsUvBPOWDMk0ADw1
 bv91Ba2+d11QsfYKX6Vc4X/6c3/YO91q1tCxfud3qpoMAAAA=
X-Change-ID: 20260829-review-ksmbd-normalized-name-v1-bf35e77fbcf7
To: Namjae Jeon <linkinjeon@kernel.org>, Steve French <smfrench@gmail.com>, 
 Sergey Senozhatsky <senozhatsky@chromium.org>, Tom Talpey <tom@talpey.com>, 
 ChenXiaoSong <chenxiaosong@chenxiaosong.com>
Cc: linux-cifs@vger.kernel.org, linux-kernel@vger.kernel.org, 
 Alon Shakevsky <shakevsky@berkeley.edu>
X-Mailer: b4 0.16.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1787984872; l=2527;
 i=shakevsky@berkeley.edu; s=20260829; h=from:subject:message-id;
 bh=T13DIXmeZ93mMwKTEaI6hlQtShB0Yg0MmpygPjeCVh8=;
 b=DMrJgpdTOB6PlJrFJXiartZD8o+rKseTf2hjZpjLWJXwa9loifYd6qewtwQkFRxNk8EHmYur6
 sF6eKXVMozQDY7X3pNuB46n1zZ/0RAYr4SzuoMlO7/3jCF2dEnx8O5r
X-Developer-Key: i=shakevsky@berkeley.edu; a=ed25519;
 pk=yWZAM5+fHWudgjDI2F4zjbrSoHRSkvQ4pqpdyFWJUis=
X-Endpoint-Received: by B4 Relay for shakevsky@berkeley.edu/20260829 with auth_id=987
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

FILE_NORMALIZED_NAME_INFORMATION converts the open file path to UTF-16.
smb2_allocate_rsp_buf() leaves these responses in the 448-byte small
buffer, and get_file_normalized_name_info() converts the path without
checking the remaining space.

An authenticated client can query a long path and make
smbConvertToUTF16() write beyond work->response_buf.

Use the large response buffer for normalized-name queries. Before
conversion, verify that the response has room for the worst-case UTF-16
output and its terminator.

Fixes: 10aeff72ab82 ("ksmbd: support normalized name information")
Assisted-by: Antiproof:GPT-5.6-Sol
Signed-off-by: Alon Shakevsky <shakevsky@berkeley.edu>
---
 fs/smb/server/smb2pdu.c | 13 +++++++++++--
 1 file changed, 11 insertions(+), 2 deletions(-)

diff --git a/fs/smb/server/smb2pdu.c b/fs/smb/server/smb2pdu.c
index a8046f477d54..0870d03dfce3 100644
--- a/fs/smb/server/smb2pdu.c
+++ b/fs/smb/server/smb2pdu.c
@@ -873,7 +873,8 @@ int smb2_allocate_rsp_buf(struct ksmbd_work *work)
 		req = smb_get_msg(work->request_buf);
 		if ((req->InfoType == SMB2_O_INFO_FILE &&
 		     (req->FileInfoClass == FILE_FULL_EA_INFORMATION ||
-		     req->FileInfoClass == FILE_ALL_INFORMATION)) ||
+		      req->FileInfoClass == FILE_ALL_INFORMATION ||
+		      req->FileInfoClass == FILE_NORMALIZED_NAME_INFORMATION)) ||
 		    req->InfoType == SMB2_O_INFO_SECURITY)
 			sz = large_sz;
 	}
@@ -6757,7 +6758,7 @@ static int get_file_normalized_name_info(struct ksmbd_work *work,
 {
 	struct smb2_file_alt_name_info *file_info;
 	char *filename, *normalized, *stream_name;
-	int conv_len, filename_len;
+	int buf_free_len, conv_len, filename_len;
 
 	if (work->conn->dialect < SMB311_PROT_ID) {
 		rsp->hdr.Status = STATUS_NOT_SUPPORTED;
@@ -6781,6 +6782,14 @@ static int get_file_normalized_name_info(struct ksmbd_work *work,
 		return -ENOMEM;
 
 	filename_len = strlen(normalized);
+	buf_free_len = smb2_resp_buf_len(work, sizeof(*rsp) +
+					 sizeof(*file_info));
+	if (buf_free_len < 0 ||
+	    (size_t)buf_free_len < (filename_len + 1) * sizeof(__le16)) {
+		kfree(normalized);
+		return -EINVAL;
+	}
+
 	file_info = (struct smb2_file_alt_name_info *)rsp->Buffer;
 	conv_len = smbConvertToUTF16((__le16 *)file_info->FileName,
 				     normalized, filename_len,

---
base-commit: cf72cbb39da84b6f02f90c07f33b102fc10b16f0
change-id: 20260829-review-ksmbd-normalized-name-v1-bf35e77fbcf7

Best regards,
--  
Alon Shakevsky <shakevsky@berkeley.edu>

