From: Nuno Sa <nuno.sa@analog.com>
Subject: [PATCH v4 0/6] iio: temperature: ltc2983: small improvements
Date: Thu, 28 Mar 2024 17:22:00 +0100
Message-Id: <20240328-ltc2983-misc-improv-v4-0-0cc428c07cd5@analog.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 8bit
X-B4-Tracking: v=1; b=H4sIACiZBWYC/22Nyw6CMBBFf4XM2jF9oFJW/odhUYcCkwAlLWk0h
 H+34tblOck9d4PoArsIdbFBcIkj+zlDeSqABjv3DrnNDEqoUih1w3ElZSqNE0dCnpbgE7aGSqs
 raZ6yg7xcguv4dVQfTeaB4+rD+zhJ+mt/PS3k317SKJCEucirJeE6utvZjr4/k5+g2ff9Ax5YN
 Du3AAAA
To: linux-kernel@vger.kernel.org, linux-iio@vger.kernel.org, 
 devicetree@vger.kernel.org
Cc: =?utf-8?q?Nuno_S=C3=A1?= <nuno.sa@analog.com>, 
 Jonathan Cameron <jic23@kernel.org>, Lars-Peter Clausen <lars@metafoo.de>, 
 Michael Hennerich <Michael.Hennerich@analog.com>, 
 Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzysztof.kozlowski+dt@linaro.org>, 
 Conor Dooley <conor+dt@kernel.org>, 
 Olivier Moysan <olivier.moysan@foss.st.com>, 
 Jyoti Bhayana <jbhayana@google.com>, 
 Krzysztof Kozlowski <krzysztof.kozlowski@linaro.org>
X-Mailer: b4 0.13.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1711642925; l=1447;
 i=nuno.sa@analog.com; s=20231116; h=from:subject:message-id;
 bh=zBhogSNxNauQDqG7V2YIRjTJ7pHNH4Qj7ezF+eXpGV0=;
 b=/wppr/f3yBPWBOrF9QxOnuWQh+UT4MUEz7k/gAKAKugqeXNaT5a/rg5waRpDGfNPv5Wo39m6h
 TQrgwlv1OSrC3RjIrcwWtqMdCtOj678YLeGrOs7R5E5A3eCH+bxU3A6
X-Developer-Key: i=nuno.sa@analog.com; a=ed25519;
 pk=3NQwYA013OUYZsmDFBf8rmyyr5iQlxV/9H4/Df83o1E=
X-Endpoint-Received: by B4 Relay for nuno.sa@analog.com/20231116 with auth_id=100
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The v4 introduces an new dev_errp_probe() helper to deal with cases
where we want to return error pointers. The refactor in the IIO ltc2983
is an heavy user of the pattern and was the main motivation for this.

Also added two new patches so we have three users of the new
dev_errp_probe() helper. 

---
Changes in v4:
- Link to v3: https://lore.kernel.org/r/20240301-ltc2983-misc-improv-v3-0-c09516ac0efc@analog.com
- Patch 1
 * New patch
- Patch 2
 * Use dev_errp_probe() instead of local variant
- Patch 5
 * New patch
- Patch 6
 * New patch

---
Nuno Sa (6):
      printk: add new dev_errp_probe() helper
      iio: temperature: ltc2983: convert to dev_err_probe()
      dt-bindings: iio: temperature: ltc2983: document power supply
      iio: temperature: ltc2983: support vdd regulator
      iio: backend: make use dev_errp_probe()
      iio: common: scmi_iio: convert to dev_err_probe()

 .../bindings/iio/temperature/adi,ltc2983.yaml      |   4 +
 drivers/iio/common/scmi_sensors/scmi_iio.c         |  45 ++--
 drivers/iio/industrialio-backend.c                 |   8 +-
 drivers/iio/temperature/ltc2983.c                  | 260 ++++++++++-----------
 include/linux/dev_printk.h                         |   5 +
 5 files changed, 151 insertions(+), 171 deletions(-)
---
base-commit: 27eea4778db8268cd6dc80a5b853c599bd3099f1
change-id: 20240227-ltc2983-misc-improv-d9c4a3819b1f
--

Thanks!
- Nuno Sá

