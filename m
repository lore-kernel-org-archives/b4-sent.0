From: Nuno Sa <nuno.sa@analog.com>
Subject: [PATCH 0/8] iio: ad9467: support interface tuning
Date: Fri, 19 Apr 2024 17:36:43 +0200
Message-Id: <20240419-ad9467-new-features-v1-0-3e7628ff6d5e@analog.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 8bit
X-B4-Tracking: v=1; b=H4sIAIuPImYC/6tWKk4tykwtVrJSqFYqSi3LLM7MzwNyDHUUlJIzE
 vPSU3UzU4B8JSMDIxMDE0NL3cQUSxMzc9281HLdtNTEktKi1GLdtKS0pMRE09SUNAMzJaDOgqL
 UtMwKsKnRsbW1AH7/8pJlAAAA
To: linux-iio@vger.kernel.org, devicetree@vger.kernel.org
Cc: Jonathan Cameron <Jonathan.Cameron@huawei.com>, 
 Alexandru Ardelean <alexandru.ardelean@analog.com>, 
 Lars-Peter Clausen <lars@metafoo.de>, 
 Michael Hennerich <Michael.Hennerich@analog.com>, 
 Jonathan Cameron <jic23@kernel.org>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzysztof.kozlowski+dt@linaro.org>, 
 Conor Dooley <conor+dt@kernel.org>, 
 Olivier Moysan <olivier.moysan@foss.st.com>, Nuno Sa <nuno.sa@analog.com>
X-Mailer: b4 0.13.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1713541010; l=2508;
 i=nuno.sa@analog.com; s=20231116; h=from:subject:message-id;
 bh=XcTC4nhrKFpu4l4Ue99zz7dLYgzqq+aK6wzay67YX2g=;
 b=Y69JHjIU3I4VRJrq1jupgSU9yq2gEXvNAZDtA7RK67ZCfN73+UG6KFO+FhOftw1bAX+wXx+Og
 7Yc5xET3WQ3DRk99dgTQfbU4b+lFS0E+T9GXsehMY2mAxYw0He7vdWp
X-Developer-Key: i=nuno.sa@analog.com; a=ed25519;
 pk=3NQwYA013OUYZsmDFBf8rmyyr5iQlxV/9H4/Df83o1E=
X-Endpoint-Received: by B4 Relay for nuno.sa@analog.com/20231116 with auth_id=100
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Hi Jonathan,

Here it goes one more set of new functionality for the backend
framework. This allows for one of the most important missing features of
the ad9467 driver. I hope the new interfaces to be fairly straight.
Though, there's one that's likely to catch your attention:

iio_backend_iodelay_set()

as you would expect (rightfully) some delay with actual units. The
reason why it does not have any units is because the IO delay thing is
mostly a calibration done at the backend level and the actually values
and timings (each tap corresponds to) is very HW specific. For example
the Xilinx/AMD zedboard has different specifications when compared to
zc706.

Given the above, I admit (:sweat smile:) I went the easier path and just added a
parameter with no meaningful unit (with proper docs). I'm definitely open
for ideas if this fells to hacky. One thing that I thought would be to
have any additional API that could be called during probe and get an
array of delays from the backend. Something like:

iio_backend_iodelays_get(back, const unsigned int **delays_ps, unsigned int *ndelays)

The backend should know what delays it supports. For the axi-adc IP we
do have registers to detect the fpga grade etc so we could return the
delays based on the HW we are running on. We would also need an addition
refclk as the actual delay each tap introduces depends on a refclk.

The series also has some "unrelated" patches for improvements and fixes. 

---
Nuno Sa (8):
      iio: backend: add API for interface tuning
      iio: adc: adi-axi-adc: only error out in major version mismatch
      dt-bindings: adc: axi-adc: add clocks property
      iio: adc: axi-adc: make sure AXI clock is enabled
      iio: adc: adi-axi-adc: remove regmap max register
      iio: adc: adi-axi-adc: support digital interface calibration
      iio: adc: ad9467: cache the sample rate
      iio: adc: ad9467: support digital interface calibration

 .../devicetree/bindings/iio/adc/adi,axi-adc.yaml   |   5 +
 drivers/iio/adc/ad9467.c                           | 340 ++++++++++++++++++---
 drivers/iio/adc/adi-axi-adc.c                      | 123 +++++++-
 drivers/iio/industrialio-backend.c                 |  86 ++++++
 include/linux/iio/backend.h                        |  57 +++-
 5 files changed, 561 insertions(+), 50 deletions(-)
---
base-commit: 62d3fb9dcc091ccdf25eb3b716e90e07e3ed861f
change-id: 20240419-ad9467-new-features-fbfbaa5edf06
--

Thanks!
- Nuno Sá

