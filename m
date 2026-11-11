From: Florian Bauckholt <florian.bauckholt@cispa.de>
Date: Wed, 11 Nov 2026 16:56:07 +0100
Subject: [PATCH 1/2] KEYS: fix signature length passed to
 KEYCTL_PKEY_VERIFY
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261111-keyctl-pkey-fixes-v1-1-934ebaa267a7@cispa.de>
References: <20261111-keyctl-pkey-fixes-v1-0-934ebaa267a7@cispa.de>
In-Reply-To: <20261111-keyctl-pkey-fixes-v1-0-934ebaa267a7@cispa.de>
To: David Howells <dhowells@redhat.com>, 
 Jarkko Sakkinen <jarkko@kernel.org>, Lukas Wunner <lukas@wunner.de>, 
 Ignat Korchagin <ignat@linux.win>, Herbert Xu <herbert@gondor.apana.org.au>, 
 "David S. Miller" <davem@davemloft.net>
Cc: Paul Moore <paul@paul-moore.com>, James Morris <jmorris@namei.org>, 
 "Serge E. Hallyn" <serge@hallyn.com>, Hui Peng <benquike@gmail.com>, 
 keyrings@vger.kernel.org, linux-crypto@vger.kernel.org, 
 linux-security-module@vger.kernel.org, linux-kernel@vger.kernel.org, 
 stable@vger.kernel.org, Florian Bauckholt <florian.bauckholt@cispa.de>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1794412620; l=1884;
 i=florian.bauckholt@cispa.de; s=20261105; h=from:subject:message-id;
 bh=LVmuxaZSH2taEYfRhlXMhvvv8Nox03oxmZ6NpX/Ry9M=;
 b=qYKEFVkNM/BmDKGEExfP2pA+Ye2Q6kqKInfaNFuLLB8Vn82lJSXEmc/WIbxgoUJIyTVq9z/df
 O7aBXzk7K35BtmDlJN0trkPlZkr7hXktWxP/vJYeyK0/hBt8Jz5YQF0
X-Developer-Key: i=florian.bauckholt@cispa.de; a=ed25519;
 pk=n9klXQ+dI45FWy0qWLrGpQfXU5ylIA0SN+uWSmOx3ok=
X-Endpoint-Received: by B4 Relay for florian.bauckholt@cispa.de/20261105 with auth_id=1420
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Commit cb481e59ea6c ("KEYS: fix overflow in keyctl_pkey_params_get_2()")
made keyctl_pkey_params_get_2() set params->out_len to the maximum
output size of the operation instead of the size provided by the caller.
It does so for KEYCTL_PKEY_VERIFY as well, but verify has no output
buffer: out_len shares a union with in2_len, the length of the
signature.

As a result keyctl_pkey_verify() ignores the signature length passed by
the caller. It copies max_sig_size bytes from the signature pointer and
passes max_sig_size as the signature size to the verification.

This makes no difference for signatures that are always max_sig_size
bytes long, such as RSA. A shorter signature, e.g. a DER-encoded ECDSA
signature, is followed by whatever is behind it in the caller's memory,
or the call fails with -EFAULT if that memory is not readable. The
x962 ECDSA template currently ignores data following the signature,
which hides the problem.

Use the length provided by the caller, which has already been checked
against max_sig_size.

Fixes: cb481e59ea6c ("KEYS: fix overflow in keyctl_pkey_params_get_2()")
Cc: stable@vger.kernel.org
Link: https://lore.kernel.org/all/20260919221742.3709658-1-benquike@gmail.com/
Signed-off-by: Florian Bauckholt <florian.bauckholt@cispa.de>
---
 security/keys/keyctl_pkey.c | 2 +-
 1 file changed, 1 insertion(+), 1 deletion(-)

diff --git a/security/keys/keyctl_pkey.c b/security/keys/keyctl_pkey.c
index 15b6bf6399b5..794fa3d01911 100644
--- a/security/keys/keyctl_pkey.c
+++ b/security/keys/keyctl_pkey.c
@@ -160,7 +160,7 @@ static int keyctl_pkey_params_get_2(const struct keyctl_pkey_params __user *_par
 		    uparams.in2_len > info.max_sig_size)
 			return -EINVAL;
 
-		params->out_len = info.max_sig_size;
+		params->in2_len = uparams.in2_len;
 		break;
 	default:
 		return -EOPNOTSUPP;

-- 
2.56.0

