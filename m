From: Joel Granados <j.granados@samsung.com>
Date: Thu, 28 Sep 2023 15:21:40 +0200
Subject: [PATCH 15/15] intel drm: Remove now superfluous sentinel element
 from ctl_table array
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20230928-jag-sysctl_remove_empty_elem_drivers-v1-15-e59120fca9f9@samsung.com>
References: <20230928-jag-sysctl_remove_empty_elem_drivers-v1-0-e59120fca9f9@samsung.com>
In-Reply-To: <20230928-jag-sysctl_remove_empty_elem_drivers-v1-0-e59120fca9f9@samsung.com>
To: Luis Chamberlain <mcgrof@kernel.org>, willy@infradead.org, 
 josh@joshtriplett.org, Kees Cook <keescook@chromium.org>, 
 Phillip Potter <phil@philpotter.co.uk>, 
 Clemens Ladisch <clemens@ladisch.de>, Arnd Bergmann <arnd@arndb.de>, 
 Greg Kroah-Hartman <gregkh@linuxfoundation.org>, 
 Juergen Gross <jgross@suse.com>, 
 Stefano Stabellini <sstabellini@kernel.org>, 
 Oleksandr Tyshchenko <oleksandr_tyshchenko@epam.com>, 
 Jiri Slaby <jirislaby@kernel.org>, 
 "James E.J. Bottomley" <jejb@linux.ibm.com>, 
 "Martin K. Petersen" <martin.petersen@oracle.com>, 
 Doug Gilbert <dgilbert@interlog.com>, 
 Sudip Mukherjee <sudipm.mukherjee@gmail.com>, 
 Jason Gunthorpe <jgg@ziepe.ca>, Leon Romanovsky <leon@kernel.org>, 
 Corey Minyard <minyard@acm.org>, Theodore Ts'o <tytso@mit.edu>, 
 "Jason A. Donenfeld" <Jason@zx2c4.com>, David Ahern <dsahern@kernel.org>, 
 "David S. Miller" <davem@davemloft.net>, Eric Dumazet <edumazet@google.com>, 
 Jakub Kicinski <kuba@kernel.org>, Paolo Abeni <pabeni@redhat.com>, 
 Robin Holt <robinmholt@gmail.com>, Steve Wahl <steve.wahl@hpe.com>, 
 Russ Weight <russell.h.weight@intel.com>, 
 "Rafael J. Wysocki" <rafael@kernel.org>, Song Liu <song@kernel.org>, 
 "K. Y. Srinivasan" <kys@microsoft.com>, 
 Haiyang Zhang <haiyangz@microsoft.com>, Wei Liu <wei.liu@kernel.org>, 
 Dexuan Cui <decui@microsoft.com>, Jani Nikula <jani.nikula@linux.intel.com>, 
 Joonas Lahtinen <joonas.lahtinen@linux.intel.com>, 
 Rodrigo Vivi <rodrigo.vivi@intel.com>, 
 Tvrtko Ursulin <tvrtko.ursulin@linux.intel.com>, 
 David Airlie <airlied@gmail.com>, Daniel Vetter <daniel@ffwll.ch>
Cc: linux-kernel@vger.kernel.org, xen-devel@lists.xenproject.org, 
 linux-serial@vger.kernel.org, linux-scsi@vger.kernel.org, 
 linuxppc-dev@lists.ozlabs.org, linux-rdma@vger.kernel.org, 
 openipmi-developer@lists.sourceforge.net, netdev@vger.kernel.org, 
 linux-raid@vger.kernel.org, linux-hyperv@vger.kernel.org, 
 intel-gfx@lists.freedesktop.org, dri-devel@lists.freedesktop.org, 
 Joel Granados <j.granados@samsung.com>
X-Mailer: b4 0.13-dev-86aa5
X-Developer-Signature: v=1; a=openpgp-sha256; l=1010;
 i=j.granados@samsung.com; h=from:subject:message-id;
 bh=Z9ZtfK3DEA99EXZ7fr8sV5mKU3DvB0mjVyvX0TU3lCI=;
 b=owEB7QES/pANAwAKAbqXzVK3lkFPAcsmYgBlFX3gFlneS4Mf90CaCbyJH1c7W29aNmmDMi/fY
 CLHmU/OGzqJAbMEAAEKAB0WIQSuRwlXJeYxJc7LJ5C6l81St5ZBTwUCZRV94AAKCRC6l81St5ZB
 T+SdC/9jFG0RUkuS7dLpAVcMO6D7jlVD+ZtX/jfu+rwthZV8WGVLtJ8kcAR7BPdgAWXivaJ86Dp
 P8HoauS68D0RI9Rl9X/gHaLDOKz2eejqJOE8LOTNyc5oeWYoHn33YzNJbhBnz6UoWV0vUdddE34
 GRQqY6MKoVxUSV4CWxcsjFchdIDzBQiMIwUqspGaJghb9FT9hzSCLfXyl5vJzx8A+y2J8mT49k2
 Zu4B/1iFwUdke4OebC6tbh93+vu6byFilf9UV3QNKYcRyJ5GGOmA8VWdq1U89/l+7ecOpeI+39E
 VAvGXaumDhZWUpNQ1QcR6XhGrFL3IBE/XkZwVuXcVyY6NfbR19/0xgBykkluiUglYLyjlLnmfcl
 5XmrIaXdLBsIKU3e2gt+wdTGHqGSyzFDdbp0RF2kkLOO1GnpNivaGGSl8okOViY6fb1bAGKWSZM
 FhB8ybdTYNi+IqN7tj+lwciJDUGicuxAJy3KGeA8aLCwF3Lo29sNp5FS7A428ifTZoZbQ=
X-Developer-Key: i=j.granados@samsung.com; a=openpgp;
 fpr=F1F8E46D30F0F6C4A45FF4465895FAAC338C6E77
X-Endpoint-Received: by B4 Relay for j.granados@samsung.com/default with auth_id=70
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

This commit comes at the tail end of a greater effort to remove the
empty elements at the end of the ctl_table arrays (sentinels) which
will reduce the overall build time size of the kernel and run time
memory bloat by ~64 bytes per sentinel (further information Link :
https://lore.kernel.org/all/ZO5Yx5JFogGi%2FcBo@bombadil.infradead.org/)

Remove sentinel from oa_table

Signed-off-by: Joel Granados <j.granados@samsung.com>
---
 drivers/gpu/drm/i915/i915_perf.c | 3 +--
 1 file changed, 1 insertion(+), 2 deletions(-)

diff --git a/drivers/gpu/drm/i915/i915_perf.c b/drivers/gpu/drm/i915/i915_perf.c
index 04bc1f4a1115..97ef6d2ad037 100644
--- a/drivers/gpu/drm/i915/i915_perf.c
+++ b/drivers/gpu/drm/i915/i915_perf.c
@@ -4895,8 +4895,7 @@ static struct ctl_table oa_table[] = {
 	 .proc_handler = proc_dointvec_minmax,
 	 .extra1 = SYSCTL_ZERO,
 	 .extra2 = &oa_sample_rate_hard_limit,
-	 },
-	{}
+	}
 };
 
 static u32 num_perf_groups_per_gt(struct intel_gt *gt)

-- 
2.30.2

