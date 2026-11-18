From: Florian Bauckholt <florian.bauckholt@cispa.de>
Date: Thu, 19 Nov 2026 00:19:28 +0100
Subject: [PATCH v2 1/2] KEYS: fix signature length passed to
 KEYCTL_PKEY_VERIFY
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261119-keyctl-pkey-fixes-v2-1-9e2d1c7db7ec@cispa.de>
References: <20261119-keyctl-pkey-fixes-v2-0-9e2d1c7db7ec@cispa.de>
In-Reply-To: <20261119-keyctl-pkey-fixes-v2-0-9e2d1c7db7ec@cispa.de>
To: David Howells <dhowells@redhat.com>, 
 Jarkko Sakkinen <jarkko@kernel.org>, Lukas Wunner <lukas@wunner.de>, 
 Ignat Korchagin <ignat@linux.win>, Herbert Xu <herbert@gondor.apana.org.au>, 
 "David S. Miller" <davem@davemloft.net>
Cc: Paul Moore <paul@paul-moore.com>, James Morris <jmorris@namei.org>, 
 "Serge E. Hallyn" <serge@hallyn.com>, Hui Peng <benquike@gmail.com>, 
 Stefan Berger <stefanb@linux.ibm.com>, 
 Rodolfo Giometti <giometti@enneenne.com>, keyrings@vger.kernel.org, 
 linux-crypto@vger.kernel.org, linux-security-module@vger.kernel.org, 
 linux-kernel@vger.kernel.org, stable@vger.kernel.org, 
 Florian Bauckholt <florian.bauckholt@cispa.de>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1795044005; l=2019;
 i=florian.bauckholt@cispa.de; s=20261105; h=from:subject:message-id;
 bh=N7REUG2kPhLJRwBc7RQwMvseCRnp8G0f0SHndQLFK84=;
 b=wSsNJ4/DKFfO0vdFGpQJfzVa8dJ017dKUNWPMWaEWXXHpVYVoAkcNfEMHgfl83BghL0USVvEF
 FXj7nNAKOtpBz1L9okSFKAosb93728onlmmj0rk1rixMNgzkKntZHh8
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
the caller and always reads max_sig_size bytes from the signature
pointer. A shorter signature is extended with whatever follows it in
the caller's memory, or the call fails with -EFAULT if that memory is
not readable.

The x962 ECDSA template currently ignores data following a DER-encoded
signature, which hides the problem there. A truncated RSA signature,
however, is accepted if the bytes following it happen to match the ones
that were cut off, as reported by Rodolfo Giometti [1].

Use the length provided by the caller, which has already been checked
against max_sig_size.

Fixes: cb481e59ea6c ("KEYS: fix overflow in keyctl_pkey_params_get_2()")
Cc: stable@vger.kernel.org
Link: https://lore.kernel.org/all/20260919221742.3709658-1-benquike@gmail.com/
Link: https://lore.kernel.org/all/0e20f799-e389-40d2-aaee-2f174748faae@enneenne.com/ [1]
Reviewed-by: Jarkko Sakkinen <jarkko@kernel.org>
Tested-by: Stefan Berger <stefanb@linux.ibm.com>
Signed-off-by: Florian Bauckholt <florian.bauckholt@cispa.de>
---
 security/keys/keyctl_pkey.c | 2 +-
 1 file changed, 1 insertion(+), 1 deletion(-)

diff --git a/security/keys/keyctl_pkey.c b/security/keys/keyctl_pkey.c
index e7121523b9c9..722521a014ab 100644
--- a/security/keys/keyctl_pkey.c
+++ b/security/keys/keyctl_pkey.c
@@ -175,7 +175,7 @@ static int keyctl_pkey_params_get_2(const struct keyctl_pkey_params __user *_par
 			goto out_up_key_sem;
 		}
 
-		params->out_len = info.max_sig_size;
+		params->in2_len = uparams.in2_len;
 		break;
 	default:
 		ret = -EOPNOTSUPP;

-- 
2.56.0

