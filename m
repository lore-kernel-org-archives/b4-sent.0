From: Florian Bauckholt <florian.bauckholt@cispa.de>
Subject: [PATCH 0/2] KEYS: two fixes for the asymmetric keyctl operations
Date: Wed, 11 Nov 2026 16:56:06 +0100
Message-Id: <20261111-keyctl-pkey-fixes-v1-0-934ebaa267a7@cispa.de>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/6tWKk4tykwtVrJSqFYqSi3LLM7MzwNyDHUUlJIzE
 vPSU3UzU4B8JSMDIzNDINDNTq1MLsnRLQDSummZFanFukZmxqYWiRbmBuZJZkpAfQVFqWAJoLb
 oWAi/uDQpKzW5BGSQUm0tAM4iKAB1AAAA
X-Change-ID: 20261111-keyctl-pkey-fixes-26358a8707b6
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
X-Developer-Signature: v=1; a=ed25519-sha256; t=1794412620; l=1414;
 i=florian.bauckholt@cispa.de; s=20261105; h=from:subject:message-id;
 bh=GOMrVRBSeE8hLfYs6YtkMRfH5HXSdleUYoeN7mchAzM=;
 b=ttCpoRZ+CbmvpkYf413TemwqzcVJRwcmDQFBw0RzMU4Y567p7HmCNsBTbuz39K5A+kzj5pEPC
 UY6g6KZOvd/CwiN08BuJKpNjqRuza+FpOi7QwafT0wnivIQ2G0SvzMu
X-Developer-Key: i=florian.bauckholt@cispa.de; a=ed25519;
 pk=n9klXQ+dI45FWy0qWLrGpQfXU5ylIA0SN+uWSmOx3ok=
X-Endpoint-Received: by B4 Relay for florian.bauckholt@cispa.de/20261105 with auth_id=1420
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Hi,

two small fixes for KEYCTL_PKEY_VERIFY and KEYCTL_PKEY_DECRYPT that I
ran into while doing differential testing of crypto implementations
with the kernel hooked up via UML:

Patch 1 fixes a regression from commit cb481e59ea6c ("KEYS: fix overflow
in keyctl_pkey_params_get_2()"), which was tagged for stable:
KEYCTL_PKEY_VERIFY ignores the signature length passed by the caller.
It also is a prerequisite for making the x962 ECDSA template reject
signatures that are not DER-encoded, which I'm posting separately to
linux-crypto.

Patch 2 fixes PKCS#1 decryption of an empty message returning the
ciphertext.

Both changes were part of a patch posted by Hui Peng in September that
did not get a reply [1]. That patch also changed the out_len checks in
keyctl_pkey_params_get_2(), which is not included here.

Thanks!

[1] https://lore.kernel.org/all/20260919221742.3709658-1-benquike@gmail.com/

---
Florian Bauckholt (2):
      KEYS: fix signature length passed to KEYCTL_PKEY_VERIFY
      KEYS: asymmetric: Fix PKCS#1 decryption of an empty message

 crypto/asymmetric_keys/public_key.c | 6 +++---
 security/keys/keyctl_pkey.c         | 2 +-
 2 files changed, 4 insertions(+), 4 deletions(-)
---
base-commit: 6628e7d4c6b25c8d18f1345e3a20d21829aae7e4
change-id: 20261111-keyctl-pkey-fixes-26358a8707b6

Best regards,
--  
Florian Bauckholt <florian.bauckholt@cispa.de>

