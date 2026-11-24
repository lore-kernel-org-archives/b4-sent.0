From: Armandas Kvietkus <armandas.kvietkus@proton.me>
Subject: [PATCH 0/4] Add FPC1540 fingerprint sensor support through QSEE
Date: Tue, 24 Nov 2026 18:42:59 +0100
Message-Id: <20261124-fpc1540-tee-v1-0-6c6985f05b06@proton.me>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/6tWKk4tykwtVrJSqFYqSi3LLM7MzwNyDHUUlJIzE
 vPSU3UzU4B8JSMDIzNDQyMT3bSCZENTEwPdktRU3WQLyyRjUyPzVHOjRCWgjoKi1LTMCrBp0bE
 QfnFpUlZqcgnICKXaWgABVT8WbwAAAA==
X-Change-ID: 20261124-fpc1540-tee-c89b3527e72a
To: Bjorn Andersson <andersson@kernel.org>, 
 Konrad Dybcio <konradybcio@kernel.org>, Abel Vesa <abelvesa@kernel.org>, 
 Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, Jonathan Corbet <corbet@lwn.net>, 
 Shuah Khan <skhan@linuxfoundation.org>, 
 Randy Dunlap <rdunlap@infradead.org>, Arnd Bergmann <arnd@arndb.de>, 
 Greg Kroah-Hartman <gregkh@linuxfoundation.org>
Cc: linux-arm-msm@vger.kernel.org, linux-kernel@vger.kernel.org, 
 devicetree@vger.kernel.org, linux-doc@vger.kernel.org, 
 Armandas Kvietkus <armandas.kvietkus@proton.me>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1795542180; l=1509;
 i=armandas.kvietkus@proton.me; h=from:subject:message-id;
 bh=xOzpTrKsIgO9EFs8IZauDfSC/Ubdmarcofr0n2Gl3BM=;
 b=AczOttScH5/OAPV3Cnqt7WmEyirdiwHPYuF3W5zL6ePdL/mVcDkBYicWVRtGm1LjC23JxPGtf
 A5Qh83g54DEDFjZPZcpqTqPDWUb9iFNXd3+mupcLsSjqbealYUKUzLG
X-Developer-Key: i=armandas.kvietkus@proton.me; a=ed25519;
 pk=wuqmImJ9sKlDVcwALOvfGhjj7G8EBjjM4TpCdmlrAf8=
X-Endpoint-Received: by B4 Relay for armandas.kvietkus@proton.me/default with auth_id=974
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

On some Qualcomm phones the FPC1540 is driven by a QSEE app and Linux
only has to power the sensor, load the app and pass commands to it.

The first patch adds the qcom_scm calls to start and stop an app and to
load a services image. The rest adds the binding and the driver, which
exposes the app to userspace through /dev/fpc_tee.

---
Armandas Kvietkus (4):
      firmware: qcom: scm: Add QSEE app start, shutdown and services image load
      dt-bindings: vendor-prefixes: Add Fingerprint Cards AB
      dt-bindings: misc: Add FPC1540 fingerprint sensor driven by a QSEE app
      misc: Add FPC1540 fingerprint sensor driver for QSEE apps

 .../devicetree/bindings/misc/fpc,fpc1540-tee.yaml  |  74 +++
 .../devicetree/bindings/vendor-prefixes.yaml       |   2 +
 Documentation/userspace-api/ioctl/ioctl-number.rst |   2 +
 MAINTAINERS                                        |   8 +
 drivers/firmware/qcom/qcom_scm.c                   |  83 ++++
 drivers/misc/Kconfig                               |  10 +
 drivers/misc/Makefile                              |   1 +
 drivers/misc/fpc1540-tee.c                         | 512 +++++++++++++++++++++
 include/linux/firmware/qcom/qcom_scm.h             |  23 +
 include/uapi/linux/fpc1540-tee.h                   |  20 +
 10 files changed, 735 insertions(+)
---
base-commit: ef922b721a5e99348fc1f5801fdeb427ee14ee9f
change-id: 20261124-fpc1540-tee-c89b3527e72a

Best regards,
--  
Armandas Kvietkus <armandas.kvietkus@proton.me>

