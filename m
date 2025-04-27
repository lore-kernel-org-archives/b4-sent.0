From: Sven Peter <sven@svenpeter.dev>
Subject: [PATCH v3 0/4] Apple/PASemi i2c error recovery fixes
Date: Sun, 27 Apr 2025 11:30:42 +0000
Message-Id: <20250427-pasemi-fixes-v3-0-af28568296c0@svenpeter.dev>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAGIVDmgC/13MTQ6CMBCG4auQrq3p30h05T2Mi9IOMguBdEijI
 dzdQmKMLN+ZfM8sGBMhi0s1i4SZmIa+hD1UInS+f6CkWFoYZUAZo+ToGZ8kW3ohy7M+haaunXK
 NF2UyJtweZXG7l+6IpyG9Nz3r9fqFzD+UtVQy1uitjaAC4JUz9iNOmI4Rs1ixbH6A07ADTAECO
 Nu0YDVovweWZfkAk4U9Uu0AAAA=
X-Change-ID: 20250220-pasemi-fixes-916cb77404ba
To: Janne Grunau <j@jannau.net>, Alyssa Rosenzweig <alyssa@rosenzweig.io>, 
 Madhavan Srinivasan <maddy@linux.ibm.com>, 
 Michael Ellerman <mpe@ellerman.id.au>, Nicholas Piggin <npiggin@gmail.com>, 
 Christophe Leroy <christophe.leroy@csgroup.eu>, 
 Naveen N Rao <naveen@kernel.org>, Andi Shyti <andi.shyti@kernel.org>, 
 Neal Gompa <neal@gompa.dev>, Hector Martin <marcan@marcan.st>
Cc: linuxppc-dev@lists.ozlabs.org, asahi@lists.linux.dev, 
 linux-arm-kernel@lists.infradead.org, linux-i2c@vger.kernel.org, 
 linux-kernel@vger.kernel.org, Sven Peter <sven@svenpeter.dev>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=openpgp-sha256; l=1791; i=sven@svenpeter.dev;
 h=from:subject:message-id; bh=+BsL+X+30brRz3phNXt0JYIMKKNWV3x6jUYpT2ksFCo=;
 b=owGbwMvMwCHmIlirolUq95LxtFoSQwafaP6/aCa2dTduGNTKVm5dHLRFrWO33Iefu73uVP578
 9RVu+hWRykLgxgHg6yYIsv2/famTx6+EVy66dJ7mDmsTCBDGLg4BWAiR3UZ/juGl3/+t3Lz1z+s
 63ZvnfBj/22L5Wl7T3Osk5l+q9xubtAihl/Mswo+Tw7s/PzwzsJpKVP/dk3f+00uItXm6OWY8mW
 rDV5xAgA=
X-Developer-Key: i=sven@svenpeter.dev; a=openpgp;
 fpr=A1E3E34A2B3C820DBC4955E5993B08092F131F93
X-Endpoint-Received: by B4 Relay for sven@svenpeter.dev/default with auth_id=167
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Hi,

This series adds a few fixes/improvements to the error recovery for
Apple/PASemi i2c controllers.
The patches have been in our downstream tree and were originally used
to debug a rare glitch caused by clock strechting but are useful in
general. We haven't seen the controller misbehave since adding these.

Best,

Sven

Signed-off-by: Sven Peter <sven@svenpeter.dev>
---
Changes in v3:
- dev_err instead of dev_warn for errors
- Added PASEMI_ prefix to the timeout define
- Declared new variables in the innermost scope they're used
- Re-added a dev_err that was dropped by mistake
- Removed already applied commits
- Removed open-coded readx_poll_timeout in the non-irq path
- Reorder commits
- Link to v2: https://lore.kernel.org/r/20250415-pasemi-fixes-v2-0-c543bf53151a@svenpeter.dev

Changes in v2:
- Added commit to use the correct include (bits.h instead of bitfield.h)
- Added commit to sort includes
- Moved timeout explanations to code instead of just the commit log
- Made timeout recovery also work correctly in the interrupt case when
  waiting for the condition failed
- Used readx_poll_timeout instead of open-coded alternative
- Link to v1: https://lore.kernel.org/r/20250222-pasemi-fixes-v1-0-d7ea33d50c5e@svenpeter.dev

---
Hector Martin (3):
      i2c: pasemi: Enable the unjam machine
      i2c: pasemi: Improve error recovery
      i2c: pasemi: Log bus reset causes

Sven Peter (1):
      i2c: pasemi: Improve timeout handling

 drivers/i2c/busses/i2c-pasemi-core.c | 107 ++++++++++++++++++++++++++++-------
 1 file changed, 88 insertions(+), 19 deletions(-)
---
base-commit: 7cfa6946c58989507a52f38a1267faa74a65ab0e
change-id: 20250220-pasemi-fixes-916cb77404ba

Best regards,
-- 
Sven Peter <sven@svenpeter.dev>

