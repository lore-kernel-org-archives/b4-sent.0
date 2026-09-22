From: Jaidev Shastri <jaidevshastri@vt.edu>
Subject: [PATCH 0/2] PM: sleep: make the async callback state explicit
Date: Mon, 21 Sep 2026 21:24:41 -0400
Message-Id: <20260921-mb-pm-main-v1-0-1d4cbd9d2b2c@vt.edu>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIANnYsWoC/yXMwQrCMBAE0F8pe3YljcGivyIeNunGrpBYslqE0
 n83qcc3zMwKykVY4dqtUHgRlVeu6A8dhInyg1HGarDGns3F9pg8zgkTSUYebTQUiQbnoA7mwlG
 ++9nt/rd+/JPDuz20hidl9IVymFq0cxmOJyzBwbb9AKT0AlOOAAAA
X-Change-ID: 20260921-mb-pm-main-ed2f0afaa744
To: "Rafael J. Wysocki" <rafael@kernel.org>, 
 Pavel Machek <pavel@kernel.org>, Len Brown <lenb@kernel.org>, 
 Greg Kroah-Hartman <gregkh@linuxfoundation.org>, 
 Danilo Krummrich <dakr@kernel.org>
Cc: linux-pm@vger.kernel.org, driver-core@lists.linux.dev, 
 linux-kernel@vger.kernel.org, Jaidev Shastri <jaidevshastri@vt.edu>
X-Mailer: b4 0.16.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1790040284; l=1062;
 i=jaidevshastri@vt.edu; s=20260921; h=from:subject:message-id;
 bh=iS/eUwwMdVFzfK8MlyhjnMq/tM9U1dbxJyRgPvGt1xw=;
 b=m/1p/8Kw0cKXFUUNs6T0+gIF2NOs8aKH948moy2ip0ShkNJVF2oq3YzqmemITIKbPS4Cg1llE
 49XebTnZxW9CWy5AvwVktstFbt5GfZjIikARkMYnuX3iQGDpcLRzY8a
X-Developer-Key: i=jaidevshastri@vt.edu; a=ed25519;
 pk=J7+xYJRlTPds+pv5hbqFFRqGCpDeJDzmZT1ggRwj7/0=
X-Endpoint-Received: by B4 Relay for jaidevshastri@vt.edu/20260921 with auth_id=1044
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The dpm_*() phase functions publish pm_transition and reset async_error
before scheduling the asynchronous device callbacks, which read both from
other CPUs.

async_schedule_dev() contains full barriers, so neither patch changes
behaviour. The first states the publication with a release/acquire pair on
pm_transition.event. The second uses WRITE_ONCE() for the async_error reset,
so that every access to that variable follows the convention its readers and
the failure paths already use.

Found with MBCheck, a static herd7-based memory consistency checker.
Compile-tested on arm64 with W=1, no new warnings.

---
Jaidev Shastri (2):
      PM: sleep: publish pm_transition with release semantics
      PM: sleep: reset async_error with WRITE_ONCE()

 drivers/base/power/main.c | 40 +++++++++++++++++++++++++---------------
 1 file changed, 25 insertions(+), 15 deletions(-)
---
base-commit: 93f51579e7df248780214094418f205253383cc5
change-id: 20260921-mb-pm-main-ed2f0afaa744

Best regards,
--  
Jaidev Shastri <jaidevshastri@vt.edu>

