From: David Heidelberg <david@ixit.cz>
Subject: [PATCH 0/4] iio: light: Modernize al3010 and al3320a codebase
Date: Sat, 08 Mar 2025 21:00:57 +0100
Message-Id: <20250308-al3010-iio-regmap-v1-0-b672535e8213@ixit.cz>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAPqhzGcC/x3MQQqAIBBA0avIrBsYlcC6SrQQm2qgVBQiiO6et
 HyL/x+oXIQrjOqBwpdUSbFBdwrC7uPGKEszGDI9WXLoD0uaUCRh4e30Gcm6wN4Oq+sXaF0uvMr
 9P6f5fT/hyCVUYwAAAA==
X-Change-ID: 20250308-al3010-iio-regmap-038cea39f85d
To: Jonathan Cameron <jic23@kernel.org>, 
 Lars-Peter Clausen <lars@metafoo.de>
Cc: Svyatoslav Ryhel <clamor95@gmail.com>, 
 Robert Eckelmann <longnoserob@gmail.com>, linux-iio@vger.kernel.org, 
 linux-kernel@vger.kernel.org, David Heidelberg <david@ixit.cz>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=openpgp-sha256; l=997; i=david@ixit.cz;
 h=from:subject:message-id; bh=xIt64jlNGpBSjIB98ZPKMCJdRE0k8D6fCTj/Gx8DeCY=;
 b=owEBbQKS/ZANAwAIAWACP8TTSSByAcsmYgBnzKJU2gbWxDF2He66jbsu8mFd4x/eox6lMFhPZ
 1tgeBFu1ZGJAjMEAAEIAB0WIQTXegnP7twrvVOnBHRgAj/E00kgcgUCZ8yiVAAKCRBgAj/E00kg
 ciySEACdR5M+iogGs02Zrg1ntWq8dguVm0uAhaOnEkpbobf8rFhLxDwNHDGmnO0XKkPY36okJ7A
 zH2qUWo41lYRtkrPu/t/Q6aLyWtF1hA/b9Wvn1ShpH+aZuv9cweQg7NyRCl9dUWFqqk7Js/vHCP
 xSEUzZ7pFR4Peh9HER7/2Qj/J61tEqRRDdanJmfbokSUGvKajlb1+TC9HsnVkS3aQPLuPMWv3B5
 UXuibBOLV6tZa2YD8zYQX09+rXjd0v5XyMsuJprlFdIDcDxCu9deO0E7sjyp3FKFfvAQgZRRWBT
 pSsalpHOcqcS8KOM0lodG63LQr7yHmZ2rmtAWLnkEBsyMvjvRJvysMK7KFdhR+daGS3k7Y918aq
 S8MqNy6hY9E47uslQZBKRE49K1UTl/010tA5ml7B5YM2Wt5yXgcC2HeBZPA3CTYOiZ31yhyl9wF
 ZtEqhd3qo/3o5XQz/BW8WbxAoZXOTAK31SEbWABLxNMBae8U+4WL9RzJrbNAv5D6yVEz01C8/N7
 PTubS511rlSIwSREyic9WN7vGhKyJCq01+DyqgAT/f89P+1srFZgaVrnoUk0gUKQm4tLsou7wuv
 okH+I/nw9SmsRtCPiPXdxfTVnP8Cy1FUKWnbbBZinOCM29yUm/ON5hGdYSJa1DXgJ5noTjHiXit
 Avhx4fP+Lk2Qm1g==
X-Developer-Key: i=david@ixit.cz; a=openpgp;
 fpr=D77A09CFEEDC2BBD53A7047460023FC4D3492072
X-Endpoint-Received: by B4 Relay for david@ixit.cz/default with auth_id=355
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

This series targetting improved readability of code
and modernizing code to match today standards.

Except slightly improved error reporting,
there shouldn't be any function changes.

Size before:
72224 al3010.ko
72744 al3320a.ko

Size after:
58032 al3010.ko
58632 al3320a.ko

Signed-off-by: David Heidelberg <david@ixit.cz>
---
David Heidelberg (4):
      iio: light: al3320a: Drop deprecated email for Daniel
      iio: light: al3000a: Use DRV_NAME
      iio: light: al3010: Implement regmap support
      iio: light: al3320a: Implement regmap support

 drivers/iio/light/al3000a.c |   6 ++-
 drivers/iio/light/al3010.c  |  95 ++++++++++++++++++++++------------------
 drivers/iio/light/al3320a.c | 103 ++++++++++++++++++++++++--------------------
 3 files changed, 114 insertions(+), 90 deletions(-)
---
base-commit: 0a2f889128969dab41861b6e40111aa03dc57014
change-id: 20250308-al3010-iio-regmap-038cea39f85d

Best regards,
-- 
David Heidelberg <david@ixit.cz>

