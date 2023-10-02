From: Joel Granados <j.granados@samsung.com>
Date: Mon, 02 Oct 2023 10:55:31 +0200
Subject: [PATCH v2 14/15] Drivers: hv: Remove now superfluous sentinel
 element from ctl_table array
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20231002-jag-sysctl_remove_empty_elem_drivers-v2-14-02dd0d46f71e@samsung.com>
References: <20231002-jag-sysctl_remove_empty_elem_drivers-v2-0-02dd0d46f71e@samsung.com>
In-Reply-To: <20231002-jag-sysctl_remove_empty_elem_drivers-v2-0-02dd0d46f71e@samsung.com>
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
Cc: Joel Granados <j.granados@samsung.com>, linux-kernel@vger.kernel.org, 
 xen-devel@lists.xenproject.org, linux-serial@vger.kernel.org, 
 linux-scsi@vger.kernel.org, linuxppc-dev@lists.ozlabs.org, 
 linux-rdma@vger.kernel.org, openipmi-developer@lists.sourceforge.net, 
 netdev@vger.kernel.org, linux-raid@vger.kernel.org, 
 linux-hyperv@vger.kernel.org, intel-gfx@lists.freedesktop.org, 
 dri-devel@lists.freedesktop.org
X-Mailer: b4 0.13-dev-86aa5
X-Developer-Signature: v=1; a=openpgp-sha256; l=895; i=j.granados@samsung.com;
 h=from:subject:message-id; bh=aRo7NVdYCvLdNgGSBgQ6l0+E6oBOdQJH07rUCLQlR94=;
 b=owEB7QES/pANAwAKAbqXzVK3lkFPAcsmYgBlGoV/RVrZ++DlZt66bGmFv2tACCjFtyc9bKCyt
 Xh72+xBYa2JAbMEAAEKAB0WIQSuRwlXJeYxJc7LJ5C6l81St5ZBTwUCZRqFfwAKCRC6l81St5ZB
 T9wCC/9S9uDWtQoaUtTyJySq/BwgMLnAny2OrneSlhO0UKqMZFvbOgUuQGiJNs8VyC7IlWrxHVm
 2gbT3WD/mQhI9WX/B0z4TarGuU+BJmzwoPPun5D3G6oUedf0JdyIZLs9TJwZyL4KbQHIhVQ8skt
 9d2ELBqWveNmV8f+e8MKgjsdagi/9I77W0Dlj2eujgXgyIiPLQ/ZS+2g+heBSUicyN16ibHEu82
 LllVj4x/NiItYuyLOncHEA6dI2/PYrOmYAHIkg5yUqWOhwDEKS4RmcYq0Y0lzUl8APdk06uQkJb
 FFdVwsBnc3/rIeI8WobAqGTPjJ+p7k6APq5wq2IG+SuGmix2X7nozc7PdKVDApIkihzXIqIdVzt
 YXt3lgmdjZI5hmlPt6RyTPvW/lX88Ru+QtyDLF7HtMgyQnjyq5zqqu1URjGJnly2oy19F7wlilb
 AGIwY7o8qjN9C7sQC6yGWy2cGGyxw/g56tiwhVyVidw8uSz1wSXK/WM5kW7C0TiW0R8hQ=
X-Developer-Key: i=j.granados@samsung.com; a=openpgp;
 fpr=F1F8E46D30F0F6C4A45FF4465895FAAC338C6E77
X-Endpoint-Received: by B4 Relay for j.granados@samsung.com/default with auth_id=70
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

This commit comes at the tail end of a greater effort to remove the
empty elements at the end of the ctl_table arrays (sentinels) which
will reduce the overall build time size of the kernel and run time
memory bloat by ~64 bytes per sentinel (further information Link :
https://lore.kernel.org/all/ZO5Yx5JFogGi%2FcBo@bombadil.infradead.org/)

Remove sentinel from hv_ctl_table

Signed-off-by: Joel Granados <j.granados@samsung.com>
---
 drivers/hv/hv_common.c | 1 -
 1 file changed, 1 deletion(-)

diff --git a/drivers/hv/hv_common.c b/drivers/hv/hv_common.c
index ccad7bca3fd3..4372f5d146ab 100644
--- a/drivers/hv/hv_common.c
+++ b/drivers/hv/hv_common.c
@@ -148,7 +148,6 @@ static struct ctl_table hv_ctl_table[] = {
 		.extra1		= SYSCTL_ZERO,
 		.extra2		= SYSCTL_ONE
 	},
-	{}
 };
 
 static int hv_die_panic_notify_crash(struct notifier_block *self,

-- 
2.30.2

