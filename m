From: Nuno Sa <nuno.sa@analog.com>
Subject: [PATCH RFC 0/8] iio: dac: support IIO backends on the output
 direction
Date: Fri, 16 Feb 2024 15:10:49 +0100
Message-Id: <20240216-iio-backend-axi-dds-v1-0-22aed9fb07a1@analog.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 8bit
X-B4-Tracking: v=1; b=H4sIAOlsz2UC/x3MMQqAMAxA0atIZgNtEAuuggdwFYdqUw1ClRZEK
 N7d4viG/zMkjsIJuipD5FuSnKFA1xWsuw0bo7hiIEWNIt2iyImLXQ8ODu0j6FxCbQz5hVSrGg+
 lvCJ7ef7rBOPQw/y+H4NjaU5qAAAA
To: linux-iio@vger.kernel.org
Cc: Jonathan Cameron <jic23@kernel.org>, 
 Lars-Peter Clausen <lars@metafoo.de>, 
 Olivier Moysan <olivier.moysan@foss.st.com>, 
 Michael Hennerich <Michael.Hennerich@analog.com>, 
 Paul Cercueil <paul@crapouillou.net>, 
 Alexandru Ardelean <ardeleanalex@gmail.com>
X-Mailer: b4 0.12.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1708092664; l=4794;
 i=nuno.sa@analog.com; s=20231116; h=from:subject:message-id;
 bh=JkdEGtgxgNJFqntuuSvbTXVlI576d1yAn17D5A/OWj8=;
 b=FKnfYoC42zMUdsaG9ZUVRLmLu5R/TvJVlueufdEAxdixb1r9B3T3IX2v+EWrtiMOcxp/g/9oJ
 KQC9ps36M4OCPc0uY/ais285EDoE0WPuBW6/fUwUPA5GHd/v2LmANeJ
X-Developer-Key: i=nuno.sa@analog.com; a=ed25519;
 pk=3NQwYA013OUYZsmDFBf8rmyyr5iQlxV/9H4/Df83o1E=
X-Endpoint-Received: by B4 Relay for nuno.sa@analog.com/20231116 with auth_id=100
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Hi all,

This RFC is mainly because I'm not getting extremely happy with the
direction of the API in the series. So I think it's better to have the
discussion now so the actual series will look better. Also note that patch
2 to 5 are brought from Paul's series to bring output buffer support to
DMA buffers [1].

So, the main API I'm speaking about is:
 - iio_backend_read_phase()
 - iio_backend_write_phase()
 - iio_backend_read_scale()
 - iio_backend_write_scale()
 - iio_backend_read_frequency()
 - iio_backend_write_frequency()

All the above is basically ABI/attributes that belong and are supported
by the AXI_DAC IP core. The main things I dislike are:
 * The sample_freq and tone_id in iio_backend_read|write_frequency().
   The API (like the others) should resemble the IIO read|write_raw()
   API and even though multiple tone waves is not something unusual, it
   would be better to keep it local to the core. The sample_freq is not
   that bad as we can eliminate it by having a new op for setting the
   sample_frquency.
 * Code duplication. Any DAC using the AXI_DAC  backend will have to define
   that extended_info.

One idea that I had was to allow to get IIO channels from the backend
but I then quickly started to dislike it because it would open a lot of
complexity. I mean, if we allow backends to define whatever they
want, that might quickly get nasty.

I guess the above comes from (maybe naive) this idea that we should be
capable to replace a backend and the IIO frontend should still work
without any change to the code. But given how the backends are tightly
coupled to the frontend (at least on ADI usecases) I think that
changing the backend is a very unlikely usecase. And if it happens it
definitely means different HW and userspace ABI so devicetree might make
sense (maybe even a new compatible).

So yes, I think it's definitely possible to have something generic where
the backend could completely define a channel (even had some ideas) but
I think the complexity it would bring is just not worth it
(at least right now). 

However, another idea that started to grow (that maybe is not that bad)
is that the IIO frontend would still define how many channels, the
channel type, which channel is buffered, etc... but allowing the backends
to extend a certain channel (the backend would be given the channel type
and it could then decide if it can or cannot extend it). We should be
careful with what we allow to extend though... For instance, in this case,
allowing to extend extended_info is likely not that bad because it's
a fairly self contained thing.

Another thing that we could consider is the info masks. Mentioning this
because (it's not part of the RFC but it should be in the real series)
the AXI_DAC also has CALIBSCALE and CALIBBIAS (I think) that can be
applied to the buffered channel. But in here, it's not that much of code
duplication to set a couple of bits in the mask and then we can just
forward the read/write to the backend... Still, maybe worth considering it
at least..

So, the above two paragraphs are kind of an intermediate approach which
does not look that crazy (or complex to implement).

Thoughts?

[1]: https://lore.kernel.org/linux-iio/20230807112113.47157-1-paul@crapouillou.net/

---
Nuno Sa (4):
      iio: buffer: add function to set the buffer direction
      iio: backend: add new backend ops
      iio: dac: add support for the AD97339A RF DAC
      iio: dac: adi-axi-dac: add support for AXI DAC IP core

Paul Cercueil (4):
      iio: buffer-dma: Rename iio_dma_buffer_data_available()
      iio: buffer-dma: Enable buffer write support
      iio: buffer-dmaengine: Support specifying buffer direction
      iio: buffer-dmaengine: Enable write support

 drivers/iio/buffer/industrialio-buffer-dma.c       | 100 +++-
 drivers/iio/buffer/industrialio-buffer-dmaengine.c |  28 +-
 drivers/iio/dac/Kconfig                            |  37 ++
 drivers/iio/dac/Makefile                           |   2 +
 drivers/iio/dac/ad9739a.c                          | 503 ++++++++++++++++++++
 drivers/iio/dac/adi-axi-dac.c                      | 510 +++++++++++++++++++++
 drivers/iio/industrialio-backend.c                 |  65 +++
 drivers/iio/industrialio-buffer.c                  |  12 +
 include/linux/iio/backend.h                        |  53 ++-
 include/linux/iio/buffer-dma.h                     |   4 +-
 include/linux/iio/buffer-dmaengine.h               |   5 +-
 include/linux/iio/buffer.h                         |   3 +
 12 files changed, 1292 insertions(+), 30 deletions(-)
---
base-commit: 7d50ed99f4d40b6fa672be971dda91a8cc8ebae4
change-id: 20240216-iio-backend-axi-dds-1772fb20604f
--

Thanks!
- Nuno Sá

