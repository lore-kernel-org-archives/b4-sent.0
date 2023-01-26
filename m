From: Niall Leonard <nl250060@ncr.com>
Subject: [PATCH 0/3] Introduce new optional property to mark port as write
 only
Date: Thu, 26 Jan 2023 10:17:21 +0000
Message-Id: <20230126-gpio-mmio-fix-v1-0-8a20ce0e8275@ncr.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIADFT0mMC/x2NwQqDQAxEf0VybmB3BcX+SukhrlFz2FWSUgTx3
 xt7GXjMPOYEYxU2eDYnKH/FZKsO8dFAXqkujDI5QwqpDTF1uOyyYSkesxwYqRum0HIeuAd3RjL
 GUanm9bYK2Yf1LnZl3/+PXu/r+gFGFfWReAAAAA==
To: Linus Walleij <linus.walleij@linaro.org>, 
 Bartosz Golaszewski <brgl@bgdev.pl>, Rob Herring <robh+dt@kernel.org>, 
 Krzysztof Kozlowski <krzysztof.kozlowski+dt@linaro.org>
Cc: linux-gpio@vger.kernel.org, devicetree@vger.kernel.org, 
 linux-kernel@vger.kernel.org, Niall Leonard <nl250060@ncr.com>
X-Mailer: b4 0.12.0
X-Developer-Signature: v=1; a=openpgp-sha256; l=1073; i=nl250060@ncr.com;
 h=from:subject:message-id; bh=pzciJ25whFPqz74uOlgRGDuqRYmNEoQWXoTcFna1QFY=;
 b=owEBbQKS/ZANAwAKAVGiIrYFD2P/AcsmYgBj0lNaon7z7C7FVt2JLo+UquDFZ/RQuxnhLYLH9Iop
 +vBmomSJAjMEAAEKAB0WIQSha1EPjh6hUqdtwZNRoiK2BQ9j/wUCY9JTWgAKCRBRoiK2BQ9j/31hD/
 9kF/j2e0BCq4ghR3YP23h4YUDmJvks7EPxhwxUpwTkoC7L8j/o4Yyz4JywsHPgy7IoQVrQTtq4v3N2
 iIJsrkLMQ0an2mkLDDJJQyTJ+WgCSAapePZ4dwzAUeuEc07dsjQo3ga1Jgk1eAImi4nD3oyr1oPZkK
 qdydor1MGIjT9jz/YxqA84ryy2/fQMR/XImwF+p8nVYMCclpY4EXw/1ZHh0Pbvn46EUjooGU3fCar6
 zrKT4kOeBhq2tN1bfsu8f/r45uUQvd0ayzP5AGewqwsWJ4dEwDTNXS9Zx+7tTeSaTiCa5y591ynvsx
 LreJiLBI/KiYLV51ZSNiZPA2gsBgfx28or7ctXckxZ+ln+Cdo5PR0/cBj5il3LeGIf3FYOrscF92n6
 TUfSf8z0Lm5OFzwnKmzfaJAERhZtxEkvu6FkNncSDeZyocZKsW8WBvoajuioUpQg68Ffyz6kZqdr9/
 nL9CRGXPuyG6p11SfVdA5FaX5wNg65qtYTFs8WFyh6ZG6dRHSNFR+3Y40Bmv8RiTFHpc4AS9gp6AR/
 JRYto98Jy7h3WkIZKeFihiJb4gzibEpq3xvucFZXN/iU03yfp89IFY2PfhmRxZlif9i3ohjqoLpj0B
 tRUlpjZCr+lujPwLp1liYMuRbjv5rExOyMxh0uHSGYMY0p0crJFK88ti6dMg==
X-Developer-Key: i=nl250060@ncr.com; a=openpgp;
 fpr=A16B510F8E1EA152A76DC19351A222B6050F63FF
X-Endpoint-Received: by B4 Submission Endpoint for nl250060@ncr.com/default with auth_id=26
List-Id: B4 Web Endpoint Patches <b4-sent.feeds.kernel.org>

Some electronics do not allow the data regsister to be read.
Reading the register can corrupt the output. This makes it
impossible to read the last data written to the port.
The existing shadow data register 'bgpio_data' can be used to allow
the last written value to be returned by the read operation in this
scenario.
This is enabled for a particular port using a new flag and a new
device tree property.

Signed-off-by: Niall Leonard <nl250060@ncr.com>
---
Niall Leonard (3):
      gpio: dt-bindings: add new property to wd,mbl-gpio bindings
      gpio: Add new flag BGPIOF_NO_INPUT
      gpio: mmio: Use new flag BGPIOF_NO_INPUT

 .../devicetree/bindings/gpio/wd,mbl-gpio.txt          |  1 +
 drivers/gpio/gpio-mmio.c                              | 19 +++++++++++++++++--
 include/linux/gpio/driver.h                           |  1 +
 3 files changed, 19 insertions(+), 2 deletions(-)
---
base-commit: 1b929c02afd37871d5afb9d498426f83432e71c2
change-id: 20230126-gpio-mmio-fix-1a69d03ec9e7

Best regards,
-- 
Niall Leonard <nl250060@ncr.com>

