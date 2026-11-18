From: Florian Bauckholt <florian.bauckholt@cispa.de>
Subject: [PATCH v2 0/2] KEYS: two fixes for the asymmetric keyctl
 operations
Date: Thu, 19 Nov 2026 00:19:27 +0100
Message-Id: <20261119-keyctl-pkey-fixes-v2-0-9e2d1c7db7ec@cispa.de>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/32NTQ6CMBCFr0Jm7ZhStEVX3sOwKGWUUQOkg0RCu
 Lst7n2byZd5PwsIBSaBc7ZAoImF+y6C3mXgW9fdCbmJDFppk0fhk2Y/vnCIF2/8IUFtimPpSqt
 sbSDmhkDbI8au1Y/lXT/Ij6koOVqWsQ/zNjrlyfevf8pR4ak4UO2cNtbZi2cZ3L4hqNZ1/QJbd
 XROwwAAAA==
X-Change-ID: 20261111-keyctl-pkey-fixes-26358a8707b6
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
X-Developer-Signature: v=1; a=ed25519-sha256; t=1795044005; l=1979;
 i=florian.bauckholt@cispa.de; s=20261105; h=from:subject:message-id;
 bh=FDAmoObBsHQBGQ+MetdjiLo0kYxapT4Ogq4Y3JdbTA8=;
 b=Wk1rAO/meq+r3f/pjo64iqVGKoS19pmqMHM9xPsXpyGDnVlWCtUdfEuvhLovt1cvaysJFtuQL
 tCvradrixlqCEdT2Je4d9Jncgq1EAGoPrSv0Mn4NmON56/1No+Asitb
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
signatures that are not DER-encoded, which I posted separately to
linux-crypto [2].

Patch 2 fixes PKCS#1 decryption of an empty message returning the
ciphertext.

Both changes were part of a patch posted by Hui Peng in September that
did not get a reply [1]. That patch also changed the out_len checks in
keyctl_pkey_params_get_2(), which is not included here.

Thanks!

[1] https://lore.kernel.org/all/20260919221742.3709658-1-benquike@gmail.com/
[2] https://lore.kernel.org/all/20261112-ecdsa-x962-der-v1-1-36b24c5f5e11@cispa.de/

---
Changes in v2:
- Rebased onto jarkko/linux-tpmdd.git for-next-keys (141b164bbe18).
  Patch 1 no longer applied after commit bab48a104447 ("KEYS: Protect
  pkey method checks against type removal"). The code change itself is
  the same.
- Patch 1: the commit message now mentions that a truncated RSA
  signature can be accepted (Rodolfo Giometti).
- Patch 2: unchanged.
- Link to v1: https://patch.msgid.link/20261111-keyctl-pkey-fixes-v1-0-934ebaa267a7@cispa.de

---
Florian Bauckholt (2):
      KEYS: fix signature length passed to KEYCTL_PKEY_VERIFY
      KEYS: asymmetric: Fix PKCS#1 decryption of an empty message

 crypto/asymmetric_keys/public_key.c | 6 +++---
 security/keys/keyctl_pkey.c         | 2 +-
 2 files changed, 4 insertions(+), 4 deletions(-)
---
base-commit: 141b164bbe186423e295b139e40e8e2d11cf1341
change-id: 20261111-keyctl-pkey-fixes-26358a8707b6

Best regards,
--  
Florian Bauckholt <florian.bauckholt@cispa.de>

