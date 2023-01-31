From: Niall Leonard <nl250060@ncr.com>
Subject: [PATCH v2 0/2] Introduce new optional property to mark port as
 write only.
Date: Tue, 31 Jan 2023 13:49:36 +0000
Message-Id: <20230126-gpio-mmio-fix-v2-0-38397aace340@ncr.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAHAc2WMC/3WNSw6DMAxEr4K8rqskqHy64h4VixBc8CIJchBqh
 bh7A/tuRnpjj94OiYQpwbPYQWjjxDFkMLcC3GzDRMhjZjDKlEqbCqeFI3qf480f1LZqR1WSa6m
 GvBlsIhzEBjefK2/TSnIeFqH8f4lefeaZ0xrle3k3fbb/FJtGhY01ypGixtSPLji5u+ihP47jB
 wXno9nBAAAA
To: Linus Walleij <linus.walleij@linaro.org>, 
 Bartosz Golaszewski <brgl@bgdev.pl>, Rob Herring <robh+dt@kernel.org>, 
 Krzysztof Kozlowski <krzysztof.kozlowski+dt@linaro.org>
Cc: linux-gpio@vger.kernel.org, devicetree@vger.kernel.org, 
 linux-kernel@vger.kernel.org, Niall Leonard <nl250060@ncr.com>
X-Mailer: b4 0.12.0
X-Developer-Signature: v=1; a=openpgp-sha256; l=1814; i=nl250060@ncr.com;
 h=from:subject:message-id; bh=1Z7cFnIaVZYHOUdHNJcuzkiLztx+3TEdtrF5p6m8WUQ=;
 b=owEBbQKS/ZANAwAKAVGiIrYFD2P/AcsmYgBj2RxylmuT5skkrTH/YOGohMmNJ8jj5UPwlHDOiDQ2
 Schczg6JAjMEAAEKAB0WIQSha1EPjh6hUqdtwZNRoiK2BQ9j/wUCY9kccgAKCRBRoiK2BQ9j/3B4EA
 CDgRlwzS6iaobZ21c4NI7EohDkC3mafEZFUC8J27JAwqTcq4dJ8TuDFD7WJm0M5a2f4j6QuvDueKpZ
 Qr3jXmaTNe+vtWSimB6FzI4sl7ZbMyRyzg0w+zlbge3WfMKitPdWVEW5KaXWz89KFs+RctteMWxp5o
 Dr8uDcBQlYPzyC3WIVfFPiZPk2L40BHik9pwUq1qey9pRVIoBFiNBKgF/K6N2SI5Opn4jkpv8t0n+e
 4O3j2BhwbkcWMFoMR8r3Ilob9FXUPgpVWZ3mh3vOBH/6ZeAk9uRIZYuC5LYsYRo0u25YL2GS8cnm2d
 KUSPSfbXch/hE95DF6ynGOuQpxyFMaqeiXn+hT60ipYFUsDNXivaukdHcLnVRRGRe7Tdh2BQ8FZ1V1
 0nUNxEWGOUPP7Uu1xViJByfk00IqLx9h7plFvFpOow63EiPqV4Ccd2IHA1RZ791V9Gccwi1kUT/c50
 5dQU3J5DV5EmPN/87s2e15MrZ18LJhFGcwF5FpjsdPEn8+UN9+KXnsAxDbqowKy+WLZM43L/izKci2
 pFTA+0ohdkPiXiQT5Bl6nxQvl4s4xc8gvkSortHZBkxJcqDaje22bgvDbObEavGg5PcgmFIFUHpBJq
 bAm7AC73+49N7SukOS4spYL6ePPlQxVRMIzbam89BQfq/sScdXKcvYbXaDkA==
X-Developer-Key: i=nl250060@ncr.com; a=openpgp;
 fpr=A16B510F8E1EA152A76DC19351A222B6050F63FF
X-Endpoint-Received: by B4 Submission Endpoint for nl250060@ncr.com/default with auth_id=26
List-Id: B4 Web Endpoint Patches <b4-sent.feeds.kernel.org>

Some electronics do not allow the data regsister to be read without
corrupting the existing data on the port. It a quirk of the board
design.
e.g. I have a couple of boards where the electronics engineer decided 
to only use the chip select line, so no read/write signal is connected. 
This means that reading the address activates the chip select and drives 
the contents of the data bus to the port.This makes it impossible to 
read the last data written to the port.

This solution is to use the existing shadow data register 'bgpio_data'.
It  can be used to return the last value written to the port by the read 
operation.
 
This is enabled for a particular port using a new flag and a new
device tree property "no-input" to allow it to be selected on a board by 
board basis. This means it will only effect hardware that requests it.

Signed-off-by: Niall Leonard <nl250060@ncr.com>
---
Changes in v2:
- Description of change updated to clarify why it is needed.
- Patches squashed as per request during review.
- wd,mbl-gpio bindings updated to yaml format.
- Link to v1: https://lore.kernel.org/r/20230126-gpio-mmio-fix-v1-0-8a20ce0e8275@ncr.com

---
Niall Leonard (2):
      dt-bindings: improve wb,mbl-gpio binding documentation.
      gpio: mmio: Use new flag BGPIOF_NO_INPUT.

 .../devicetree/bindings/gpio/wd,mbl-gpio.txt       | 38 -----------
 .../devicetree/bindings/gpio/wd,mbl-gpio.yaml      | 78 ++++++++++++++++++++++
 drivers/gpio/gpio-mmio.c                           | 24 ++++++-
 include/linux/gpio/driver.h                        |  1 +
 4 files changed, 100 insertions(+), 41 deletions(-)
---
base-commit: 1b929c02afd37871d5afb9d498426f83432e71c2
change-id: 20230126-gpio-mmio-fix-1a69d03ec9e7

Best regards,
-- 
Niall Leonard <nl250060@ncr.com>

