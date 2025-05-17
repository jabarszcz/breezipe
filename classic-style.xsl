<?xml version="1.0" encoding="UTF-8"?>
<transform
    version="1.0"
    xmlns="http://www.w3.org/1999/XSL/Transform"
    xmlns:xhtml="http://www.w3.org/1999/xhtml"
    xmlns:br="http://jabarsz.cz/Breezipe"
    xmlns:exsl="http://exslt.org/common"
    extension-element-prefixes="exsl">

  <import href="./common.xsl" />
  <output indent="yes" />

  <!-- Entry points: mise-en-place & classic-steps -->

  <!-- Mise en place -->

  <template name="mise-en-place">
    <xhtml:table>
      <apply-templates mode="mise-en-place-tbody" />
    </xhtml:table>
  </template>

  <!-- Don't copy text -->
  <template match="text()" mode="mise-en-place-tbody" />
  <template match="text()" mode="mise-en-place" />

  <template match="br:step" mode="mise-en-place-tbody">
    <apply-templates mode="mise-en-place-tbody" />
  </template>

  <template match="br:group" mode="mise-en-place-tbody">
    <!-- Named ingredient groups get a table header -->
    <xhtml:tbody>
      <variable name="group-name-tmp">
        <call-template name="get-name" />
      </variable>
      <variable name="group-name" select="exsl:node-set($group-name-tmp)" />
      <if test="$group-name != ''">
        <xhtml:tr>
          <call-template name="class-attr" />
          <xhtml:th colspan="2">
            <call-template name="link">
              <with-param name="text" select="$group-name" />
            </call-template>
          </xhtml:th>
        </xhtml:tr>
      </if>
      <apply-templates mode="mise-en-place" />
    </xhtml:tbody>
  </template>

  <template match="br:ingredient|
                   br:ref[key('id', @r)/self::br:recipe]"
            mode="mise-en-place-tbody">
    <xhtml:tbody>
      <apply-templates mode="mise-en-place" select="." />
    </xhtml:tbody>
  </template>

  <template match="br:ingredient|
                   br:ref[key('id', @r)/self::br:recipe]"
            mode="mise-en-place">
    <xhtml:tr>
      <call-template name="class-attr" />
      <xhtml:td>
        <call-template name="get-quantity" />
      </xhtml:td>
      <xhtml:td>
        <call-template name="link">
          <with-param name="extra-classes">
            <if test="br:ingredient">ingredient</if>
          </with-param>
        </call-template>
        <if test="@note"> (<value-of select="@note" />)</if>
        <if test="br:note"> (<copy-of select="br:note/node()" />)</if>
      </xhtml:td>
    </xhtml:tr>
  </template>

  <!-- Instructions -->

  <template name="classic-steps">
    <param name="with-targets" select="true()" />
    <xhtml:ol>
      <apply-templates select="br:step" mode="classic-steps">
        <with-param name="with-targets" select="$with-targets" />
      </apply-templates>
    </xhtml:ol>
  </template>

  <template match="br:step" mode="classic-steps">
    <param name="with-targets" select="true()" />
    <xhtml:li>
      <call-template name="class-attr">
        <with-param name="extra-classes" select="'step'" />
      </call-template>
      <if test="$with-targets">
        <call-template name="target" />
      </if>
      <if test="@short">
        <xhtml:b><value-of select="@short" />. </xhtml:b>
      </if>
      <apply-templates mode="classic-steps">
        <with-param name="with-targets" select="$with-targets" />
      </apply-templates>
    </xhtml:li>
  </template>

  <template match="br:group" mode="classic-steps">
    <param name="with-targets" select="true()" />
    <xhtml:span>
      <call-template name="class-attr">
        <with-param name="extra-classes" select="'step-group'" />
      </call-template>
      <if test="$with-targets">
        <call-template name="target" />
      </if>
      <apply-templates mode="classic-steps">
        <with-param name="with-targets" select="$with-targets" />
      </apply-templates>
    </xhtml:span>
  </template>

  <template match="br:ingredient" mode="classic-steps">
    <param name="with-targets" select="true()" />
    <xhtml:span>
      <call-template name="class-attr">
        <with-param name="extra-classes" select="'step-ingredient'" />
      </call-template>
      <if test="$with-targets">
        <call-template name="target" />
      </if>
      <call-template name="link" />
      <call-template name="qty-note-parens" />
    </xhtml:span>
  </template>

  <template match="br:ref" mode="classic-steps">
    <xhtml:span>
      <attribute name="class">
        <text>crossrefd </text>
        <value-of select="@r" />
      </attribute>
      <attribute name="data-crossref"> <value-of select="@r" /> </attribute>
      <xhtml:a class="internal">
        <attribute name="href">#<value-of select="@r" /></attribute>
        <choose>
          <when test="node()">
            <apply-templates /> <!-- Copy inner text/xhtml -->
          </when>
          <otherwise>
            <apply-templates select="key('id', @r)" mode="get-name-or-id" />
          </otherwise>
        </choose>
      </xhtml:a>
      <call-template name="qty-note-parens" />
    </xhtml:span>
  </template>

  <template match="br:result" mode="classic-steps">
    <param name="with-targets" select="true()" />
    <call-template name="link">
      <with-param name="extra-classes">
        <call-template name="crossrefd" />
      </with-param>
      <with-param name="extra-attrs-from">
        <xhtml:a>               <!-- Dummy node to pass attrs -->
          <if test="$with-targets">
            <call-template name="target" />
          </if>
          <attribute name="data-crossref">
            <call-template name="get-id" />
          </attribute>
        </xhtml:a>
      </with-param>
    </call-template>
  </template>

</transform>
