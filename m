From: Eduardo Pereira Cruz <dreduardocruz@gmail.com>
Date: Sun, 22 Nov 2026 11:31:12 -0300
Subject: [PATCH] docs/translations/pt_BR: process: add
 generated-content.rst
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 8bit
Message-Id: <20261122-generated-content-pt-br-v1-1-3462e22d7b5d@gmail.com>
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/yXMQQrCMBBG4auUWTtgQonRq4iLJv2t4yItk6kIp
 Xc36vJbvLdRhQoqXbqNFC+pMpcGd+goP4YygWVsJn/0wTnveUKBDoaR81wMxXgxTsoxh9CHdI7
 9KVKrF8Vd3r/z9fZ3XdMT2b472vcPjHhRNnsAAAA=
X-Change-ID: 20261122-generated-content-pt-br-8c6646b98478
To: linux-doc@vger.kernel.org
Cc: corbet@lwn.net, danielmaraboo@gmail.com, rdunlap@infradead.org, 
 skhan@linuxfoundation.org, Eduardo Pereira Cruz <dreduardocruz@gmail.com>
X-Mailer: b4 0.16.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1795357871; l=7364;
 i=dreduardocruz@gmail.com; s=20261119; h=from:subject:message-id;
 bh=vo81soZDHoCodR9WtIkcpWbMvZKc7+lumNVuyAZ09og=;
 b=WrnSfPoOEHN111ZAFEao4EkLSobIKCWMqL2x780NR7Xw0WwX5AYpNHBx2YGLao9bYOMKFy3u4
 B1flBD2Vd5QCAJk6lWLrWyzC5JrqrgkDhjQxbywnIbKAGCTpPtKV3+q
X-Developer-Key: i=dreduardocruz@gmail.com; a=ed25519;
 pk=2dtL+BL/x70sROmAvlskv9dbjj274zlPkLBVu4gJJiA=
X-Endpoint-Received: by B4 Relay for dreduardocruz@gmail.com/20261119 with auth_id=1571
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Add the Brazilian Portuguese translation of
Documentation/process/generated-content.rst, which describes the kernel
community expectations for contributions generated with tools, including
what to disclose in cover letters and changelogs.

The translation follows the English original as last committed and keeps
the four lists, the inline code spans naming the tools and the reference
to the Developer's Certificate of Origin.

Signed-off-by: Eduardo Pereira Cruz <dreduardocruz@gmail.com>
---
 .../pt_BR/process/generated-content.rst            | 122 +++++++++++++++++++++
 Documentation/translations/pt_BR/process/index.rst |   1 +
 2 files changed, 123 insertions(+)

diff --git a/Documentation/translations/pt_BR/process/generated-content.rst b/Documentation/translations/pt_BR/process/generated-content.rst
new file mode 100644
index 000000000000..8ba3348c1692
--- /dev/null
+++ b/Documentation/translations/pt_BR/process/generated-content.rst
@@ -0,0 +1,122 @@
+.. SPDX-License-Identifier: GPL-2.0
+
+=========================================================
+Diretrizes do kernel para conteúdo gerado por ferramentas
+=========================================================
+
+Propósito
+=========
+
+Colaboradores do kernel usam ferramentas para gerar contribuições há muito
+tempo. Essas ferramentas podem aumentar o volume de contribuições. Ao mesmo
+tempo, o tempo disponível de revisores e mantenedores é um recurso escasso.
+Entender quais partes de uma contribuição vêm de humanos e quais vêm de
+ferramentas ajuda a preservar esses recursos e a manter o desenvolvimento
+do kernel saudável.
+
+O objetivo aqui é esclarecer as expectativas da comunidade em relação às
+ferramentas. Isso permite que todos se tornem mais produtivos e, ao mesmo
+tempo, mantenham altos níveis de confiança entre quem envia e quem revisa.
+
+Fora de escopo
+==============
+
+Estas diretrizes não se aplicam a ferramentas que fazem ajustes triviais em
+conteúdo preexistente. Nem dizem respeito a ferramentas que ajudam em
+tarefas rotineiras. Alguns exemplos:
+
+ - Correções de ortografia e gramática, como reescrever para o modo
+   imperativo
+ - Auxílios de digitação, como completar identificadores, boilerplate comum
+   ou padrões triviais
+ - Transformações puramente mecânicas, como renomear variáveis
+ - Reformatação, como rodar Lindent, ``clang-format`` ou ``rust-fmt``
+
+Mesmo quando o uso da ferramenta estiver fora de escopo, você ainda deve
+sempre considerar se o revisor saber qual ferramenta foi usada ajudaria na
+revisão da sua contribuição.
+
+Dentro do escopo
+================
+
+Estas diretrizes se aplicam quando uma quantidade significativa de conteúdo
+de uma contribuição ao kernel não foi escrita por uma pessoa na cadeia de
+Signed-off-by, mas foi criada por uma ferramenta.
+
+Detectar um problema e testar a correção para ele também faz parte do
+processo de desenvolvimento; se uma ferramenta foi usada para encontrar um
+problema tratado por uma mudança, isso deve ser anotado no changelog. Isso
+não apenas dá o crédito devido, como também ajuda outros desenvolvedores a
+conhecer essas ferramentas.
+
+Alguns exemplos:
+
+ - Qualquer correção sugerida por ferramenta, como ``checkpatch.pl --fix``
+ - Scripts Coccinelle
+ - Um chatbot gerou uma nova função no seu patch para ordenar entradas de
+   lista.
+ - Um arquivo .c do patch foi originalmente gerado por um assistente de
+   código, mas limpo à mão.
+ - O changelog foi gerado entregando o patch a uma ferramenta de IA
+   generativa e pedindo que ela escrevesse o changelog.
+ - O changelog foi traduzido de outro idioma.
+
+Em caso de dúvida, escolha a transparência e presuma que estas diretrizes
+se aplicam à sua contribuição.
+
+Diretrizes
+==========
+
+Primeiro, leia o Developer's Certificate of Origin:
+Documentation/process/submitting-patches.rst. As regras são simples e
+existem há muito tempo. Elas vêm cobrindo muitas contribuições geradas por
+ferramentas. Garanta que você entende toda a sua submissão e que está
+preparado para responder aos comentários de revisão.
+
+Segundo, ao fazer uma contribuição, seja transparente sobre a origem do
+conteúdo nas cover letters e nos changelogs. Você pode ser mais
+transparente incluindo informações como:
+
+ - Quais ferramentas foram usadas?
+ - A entrada fornecida às ferramentas usadas, como o script fonte do
+   Coccinelle.
+ - Se o código foi gerado em grande parte a partir de um único prompt ou de
+   um conjunto curto deles, inclua esses prompts. Para sessões mais longas,
+   inclua um resumo dos prompts e a natureza da assistência resultante.
+ - Quais partes do conteúdo foram afetadas por aquela ferramenta?
+ - Como a submissão foi testada e quais ferramentas foram usadas para
+   testar a correção?
+
+Como em todas as contribuições, cada mantenedor tem discricionariedade para
+escolher como lidar com a contribuição. Por exemplo, ele pode:
+
+ - Tratá-la como qualquer outra contribuição.
+ - Rejeitá-la de imediato.
+ - Tratar a contribuição de forma especial, por exemplo, pedindo testes
+   adicionais, revisando com escrutínio extra ou revisando com prioridade
+   menor do que o conteúdo gerado por humanos.
+ - Pedir outros passos especiais, como solicitar ao colaborador que
+   detalhe como a ferramenta ou o modelo foi treinado.
+ - Pedir a quem envia que explique a contribuição em mais detalhes, para
+   que o mantenedor tenha certeza de que a pessoa entende plenamente como o
+   código funciona.
+ - Sugerir um prompt melhor em vez de sugerir mudanças específicas no
+   código.
+
+Se as ferramentas permitirem gerar uma contribuição automaticamente, espere
+escrutínio adicional proporcional à quantidade gerada.
+
+Assim como ocorre com a saída de qualquer ferramenta, o resultado pode estar
+incorreto ou ser inadequado. Espera-se que você entenda e consiga defender
+tudo o que envia. Se não conseguir fazer isso, não envie as mudanças
+resultantes.
+
+Se enviar mesmo assim, os mantenedores têm o direito de rejeitar a sua
+série sem revisão detalhada.
+
+Referências
+===========
+
+Para diretrizes específicas sobre assistentes de código com IA, veja:
+
+* Documentation/process/coding-assistants.rst
diff --git a/Documentation/translations/pt_BR/process/index.rst b/Documentation/translations/pt_BR/process/index.rst
index d072f7e46767..d2dd4bf02675 100644
--- a/Documentation/translations/pt_BR/process/index.rst
+++ b/Documentation/translations/pt_BR/process/index.rst
@@ -46,6 +46,7 @@ devem estar familiarizados.
    Adicionando uma nova chamada de Sistema <adding-syscalls>
    Por que a classe de tipo "volatile" não deve ser usada <volatile-considered-harmful>
    Como não Deixar as ioctls malfeitas <botching-up-ioctls>
+   Conteúdo gerado por ferramentas <generated-content>
 
 Guias de políticas e declarações de desenvolvedores
 ---------------------------------------------------

---
base-commit: 4405c18c95d2d0f99f6c581ef0ee8591a1aa6ccd
change-id: 20261122-generated-content-pt-br-8c6646b98478

Best regards,
--  
Eduardo Pereira Cruz <dreduardocruz@gmail.com>

