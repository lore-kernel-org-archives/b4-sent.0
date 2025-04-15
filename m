From: Sven Peter <sven@svenpeter.dev>
Subject: [PATCH v2 0/6] Apple/PASemi i2c error recovery fixes
Date: Tue, 15 Apr 2025 15:36:54 +0000
Message-Id: <20250415-pasemi-fixes-v2-0-c543bf53151a@svenpeter.dev>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIABZ9/mcC/1WMQQ6CMBREr0L+2pq2gERX3sOwKHSUvxCaftJoS
 O9uJXHh8s3kvY0EkSF0qTaKSCy8zAXsoaJxcvMDin1hstq22lqtghM8Wd35BVFncxqHrmt0Mzg
 qSojYj2Lc+sITy7rE915P5rv+QvY/lIzSyndwde1bPba4SsIcsCIePRL1OecPBfj1sawAAAA=
X-Change-ID: 20250220-pasemi-fixes-916cb77404ba
To: Janne Grunau <j@jannau.net>, Alyssa Rosenzweig <alyssa@rosenzweig.io>, 
 Madhavan Srinivasan <maddy@linux.ibm.com>, 
 Michael Ellerman <mpe@ellerman.id.au>, Nicholas Piggin <npiggin@gmail.com>, 
 Christophe Leroy <christophe.leroy@csgroup.eu>, 
 Naveen N Rao <naveen@kernel.org>, Andi Shyti <andi.shyti@kernel.org>, 
 Neal Gompa <neal@gompa.dev>, Hector Martin <marcan@marcan.st>
Cc: linuxppc-dev@lists.ozlabs.org, asahi@lists.linux.dev, 
 linux-arm-kernel@lists.infradead.org, linux-i2c@vger.kernel.org, 
 linux-kernel@vger.kernel.org, Sven Peter <sven@svenpeter.dev>, 
 Andy Shevchenko <andy.shevchenko@gmail.com>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=openpgp-sha256; l=1509; i=sven@svenpeter.dev;
 h=from:subject:message-id; bh=ymN+LyNWSLpbDsTvqi1RfS1hGNC4G0Ay2QtUtBcebSE=;
 b=owGbwMvMwCHmIlirolUq95LxtFoSQ/q/WqW39UeZ2Vs4Hu471P1vrbLFhq3/9kvNXFKdzyq+j
 7MlkbWwo5SFQYyDQVZMkWX7fnvTJw/fCC7ddOk9zBxWJpAhDFycAjCRm0IM/0y7N11kSl4vsPBN
 e11CRPJmjTvNtzVf/ehWW7f33Wexj76MDEc5bobPYdU5tcPjyDnljo4tLnwHrzcd9mDs/BEcN79
 4Ej8A
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
      i2c: pasemi: Improve error recovery
      i2c: pasemi: Enable the unjam machine
      i2c: pasemi: Log bus reset causes

Sven Peter (3):
      i2c: pasemi: Use correct bits.h include
      i2c: pasemi: Sort includes alphabetically
      i2c: pasemi: Improve timeout handling

 drivers/i2c/busses/i2c-pasemi-core.c | 114 ++++++++++++++++++++++++++++-------
 drivers/i2c/busses/i2c-pasemi-pci.c  |  10 +--
 2 files changed, 96 insertions(+), 28 deletions(-)
---
base-commit: 0af2f6be1b4281385b618cb86ad946eded089ac8
change-id: 20250220-pasemi-fixes-916cb77404ba

Best regards,
-- 
Sven Peter <sven@svenpeter.dev>

