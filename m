From: Nuno Sa <nuno.sa@analog.com>
Subject: [PATCH v3 0/2] iio: adc: adi-axi-adc: make sure DRP is locked on
 enable
Date: Fri, 31 May 2024 11:41:53 +0200
Message-Id: <20240531-dev-axi-adc-drp-v3-0-e3fa79447c67@analog.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 8bit
X-B4-Tracking: v=1; b=H4sIAGGbWWYC/3XNQQ6CMBCF4auYrh3TFijUlfcwLoZ2gCZKSWsaD
 OHuFlYa4/J/yXyzsEjBUWTnw8ICJRedH3MUxwMzA449gbO5meSy5BVXYCkBzg7QGrBhAiTVWm0
 LqUTN8tUUqHPzLl5vuQcXnz689gdJbOt/KwkQ0FiFTaU6zTVdcMS770/GP9iGJfkBSPkLyAy0q
 jC61hzLBr+AdV3fAiTUp/AAAAA=
To: linux-iio@vger.kernel.org
Cc: Lars-Peter Clausen <lars@metafoo.de>, 
 Michael Hennerich <Michael.Hennerich@analog.com>, 
 Jonathan Cameron <jic23@kernel.org>, David Lechner <dlechner@baylibre.com>
X-Mailer: b4 0.13.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1717148521; l=674;
 i=nuno.sa@analog.com; s=20231116; h=from:subject:message-id;
 bh=R3CwbVDWIO5pU2ln/yLqWT9OQjKOkcvucZEd/QgBnzI=;
 b=xHcm4gO66Se4fcL0Gk7rnBcOqPtV6p51F/+WhW4qwQbq7GFFlZgcetFKWoFpmxmhctlxaco8f
 q1y1NQz+892Au758izc1KNxSnVWvyrbfZptonvkZSGTPvoztP7yofkf
X-Developer-Key: i=nuno.sa@analog.com; a=ed25519;
 pk=3NQwYA013OUYZsmDFBf8rmyyr5iQlxV/9H4/Df83o1E=
X-Endpoint-Received: by B4 Relay for nuno.sa@analog.com/20231116 with auth_id=100
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Hi Jonathan,

Here it goes my v3. Just splits the fix (with a proper tag)  in it's own patch.

---
Changes in v3:
- Patch 1
  * New patch.
- Patch 2
  * No changes.
- Link to v2: https://lore.kernel.org/r/20240522-dev-axi-adc-drp-v2-1-b63c9790a48a@analog.com

---
Nuno Sa (2):
      iio: adc: adi-axi-adc: don't allow concurrent enable/disable calls
      iio: adc: adi-axi-adc: make sure DRP is locked on enable

 drivers/iio/adc/adi-axi-adc.c | 18 +++++++++++++++++-
 1 file changed, 17 insertions(+), 1 deletion(-)
---
base-commit: 5e3c5871138da700796587aa5f096d39135f9d36
change-id: 20240506-dev-axi-adc-drp-ae6bd9d32617
--

Thanks!
- Nuno Sá

