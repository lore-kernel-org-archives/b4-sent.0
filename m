From: Junye Ji <jijunye1@outlook.com>
Date: Sun, 12 Jul 2026 13:21:34 -0700
Subject: [PATCH] ksmbd: fix channel_key buffer overflow in multichannel
 binding
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260712-ksmbd-channel-key-size-v1-1-84818ee5cdc6@outlook.com>
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/x2MwQqDMBAFf0X27EISQaG/Ih5i8mwX2yhZEFvx3
 409DsPMQYosUHpUB2VsorKkArauKLx8eoIlFiZnXGs663jWzxj5dglvnvFllR+48T7YEW1noqc
 SrxmT7P9xP5znBfS6lIloAAAA
X-Change-ID: 20260712-ksmbd-channel-key-size-3aac1be670da
To: Namjae Jeon <linkinjeon@kernel.org>, Steve French <smfrench@gmail.com>
Cc: Sergey Senozhatsky <senozhatsky@chromium.org>, 
 Tom Talpey <tom@talpey.com>, linux-cifs@vger.kernel.org, 
 linux-kernel@vger.kernel.org, Junye Ji <jijunye1@outlook.com>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1783887697; l=2135;
 i=jijunye1@outlook.com; s=junyeji-20260712; h=from:subject:message-id;
 bh=EOdOm1GfTA2/I0Ll/QriqK8l0t3oPN69zpkBPVqhF8I=;
 b=wtFz03WG85r4FIne2u8SIsrrW43TFhTL9y+0rfOeujS/+Ygn6w1NGzglIuKdP0S/QDydL2ZnA
 e1BmL2L3ou1C82isleatKwsC98nn7sfNgC+SbaNkE1SE8R4ZSFiLeZ2
X-Developer-Key: i=jijunye1@outlook.com; a=ed25519;
 pk=aKIN8hT1V9oSVC83K2q1NNzawUnDaybDxbYJltmwvGE=
X-Endpoint-Received: by B4 Relay for jijunye1@outlook.com/junyeji-20260712 with auth_id=865
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

ksmbd_decode_ntlmssp_auth_blob() and ksmbd_krb5_authenticate() can write
keys up to CIFS_KEY_SIZE. During SMB3 multichannel binding, their
destination is the 16-byte channel_key stack buffer, so longer keys
overwrite the stack.

Size the temporary buffers for the accepted maximum.
register_session_channel() still stores a 16-byte channel key.

I reproduced the stack write with 17- and 40-byte NTLM keys and a
32-byte Kerberos subkey. On the fixed KASAN kernel, 16-, 17-, and 40-byte
NTLM keys and 16- and 32-byte Kerberos subkeys completed 10 bindings each
without a report. The existing length check still rejected a 41-byte
NTLM key.

Fixes: 4b706360ffb7 ("ksmbd: fix multichannel binding and enforce channel limit")
Assisted-by: Codex-Security:unspecified
Signed-off-by: Junye Ji <jijunye1@outlook.com>
---
I can send the reproducers and full KASAN logs privately if needed.
---
 fs/smb/server/smb2pdu.c | 4 ++--
 1 file changed, 2 insertions(+), 2 deletions(-)

diff --git a/fs/smb/server/smb2pdu.c b/fs/smb/server/smb2pdu.c
index b73167785e87..d8a7db655043 100644
--- a/fs/smb/server/smb2pdu.c
+++ b/fs/smb/server/smb2pdu.c
@@ -1689,7 +1689,7 @@ static int ntlm_authenticate(struct ksmbd_work *work,
 	struct ksmbd_conn *conn = work->conn;
 	struct ksmbd_session *sess = work->sess;
 	struct ksmbd_user *user;
-	char channel_key[SMB2_NTLMV2_SESSKEY_SIZE] = {};
+	char channel_key[CIFS_KEY_SIZE] = {};
 	char *auth_key = conn->binding ? channel_key : sess->sess_key;
 	u64 prev_id;
 	bool binding = conn->binding;
@@ -1826,7 +1826,7 @@ static int krb5_authenticate(struct ksmbd_work *work,
 	struct ksmbd_conn *conn = work->conn;
 	struct ksmbd_session *sess = work->sess;
 	char *in_blob, *out_blob;
-	char channel_key[SMB2_NTLMV2_SESSKEY_SIZE] = {};
+	char channel_key[CIFS_KEY_SIZE] = {};
 	char *auth_key = conn->binding ? channel_key : sess->sess_key;
 	u64 prev_sess_id;
 	bool binding = conn->binding;

---
base-commit: 44696aa3a489d2baf58efa61b37833f100072bee
change-id: 20260712-ksmbd-channel-key-size-3aac1be670da

Best regards,
-- 
Junye Ji <jijunye1@outlook.com>

