<?xml version="1.0" encoding="UTF-8"?>
<transform
    version="1.0"
    xmlns="http://www.w3.org/1999/XSL/Transform"
    xmlns:xhtml="http://www.w3.org/1999/xhtml"
    xmlns:br="http://jabarsz.cz/Breezipe"
    xmlns:exsl="http://exslt.org/common"
    xmlns:set="http://exslt.org/sets"
    xmlns:math="http://exslt.org/math"
    extension-element-prefixes="exsl set math">

  <import href="./common.xsl" />
  <output indent="yes" />

  <!-- Entry point template -->
  <template name="step-table">
    <param name="step-set" select=".//br:step" />
    <param name="with-notes" select="true()" />

    <!-- Annotate a tree of the recipe with useful info for computing
         the order of the transitively referenced leaves. -->
    <variable name="inlined-step-refs">
      <apply-templates select="$step-set[last()]"
                       mode="inline-step-refs" />
    </variable>
    <variable name="annotated-tmp">
      <apply-templates select="exsl:node-set($inlined-step-refs)"
                       mode="annotate-inlined" />
    </variable>
    <variable name="annotated" select="exsl:node-set($annotated-tmp)" />

    <!-- Compute the transitively referenced "leaves" which constitute
         the left column of the ingredient-step table. They comprise
         not only ingredients, but also ingredient-less steps and
         secondary step results. -->
    <variable name="refd">
      <for-each select="$step-set[last()]">
        <call-template name="transitively-referenced-leaves">
          <with-param name="annotated" select="$annotated" />
        </call-template>
      </for-each>
    </variable>

    <xhtml:table class="step-table">
      <xhtml:tr>                <!-- A row to set non-0 column widths -->
        <xhtml:th />            <!-- One column for ingredients -->
        <for-each select="$step-set"> <!-- Then one per step -->
          <xhtml:th />
        </for-each>
      </xhtml:tr>
      <for-each select="exsl:node-set($refd)/node()">
        <xhtml:tr>
          <choose>
            <when test="self::br:step"><xhtml:td /></when>
            <when test="self::br:ingredient|self::br:recipe">
              <xhtml:td>
                <call-template name="class-attr" />
                <if test="@quantity">
                  <call-template name="get-quantity" />
                  <text> </text>
                </if>
                <choose>
                  <when test="self::br:ingredient">
                    <call-template name="link">
                      <with-param name="extra-classes">
                        <text>ingredient</text>
                      </with-param>
                    </call-template>
                  </when>
                  <when test="self::br:recipe">
                    <call-template name="link">
                      <with-param name="text">
                        <call-template name="get-name" />
                      </with-param>
                      <with-param name="extra-classes">
                        <text>recipe</text>
                      </with-param>
                    </call-template>
                  </when>
                </choose>
                <if test="$with-notes">
                  <if test="@note"> (<value-of select="@note" />)</if>
                  <if test="br:note"> (<copy-of select="br:note/node()" />)</if>
                </if>
              </xhtml:td>
            </when>
          </choose>
          <variable name="gid" select="@generated-id" />
          <variable name="steps-pre-occur">
            <for-each select="$step-set">
              <if test=".//node()[generate-id()=$gid]">
                <number value="position()" />
              </if>
            </for-each>
          </variable>
          <choose>
            <when test="self::br:step|
                        self::br:ingredient|
                        self::br:recipe">
              <if test="$steps-pre-occur > 1">
                <xhtml:td>
                  <attribute name="colspan">
                    <number value="$steps-pre-occur - 1" />
                  </attribute>
                </xhtml:td>
              </if>
            </when>
            <when test="self::br:result">
              <variable name="rid" select="@id" />
              <variable name="steps-pre-ref">
                <for-each select="$step-set">
                  <if test="br:ref[@r=$rid]">
                    <number value="position()" />
                  </if>
                </for-each>
              </variable>
              <xhtml:td>
                <attribute name="colspan">
                  <number value="$steps-pre-occur + 1" />
                </attribute>
                <call-template name="class-attr" />
                <call-template name="link">
                  <with-param name="text">
                    <choose>
                      <when test="text()"><apply-templates /></when>
                      <otherwise>
                        <call-template name="get-name-or-id" />
                      </otherwise>
                    </choose>
                  </with-param>
                </call-template>
                <text>⤷</text>
              </xhtml:td>
              <variable name="additional-steps"
                        select="$steps-pre-ref - $steps-pre-occur - 1" />
              <if test="$additional-steps > 0">
                <xhtml:td>
                  <attribute name="colspan">
                    <number value="$additional-steps" />
                  </attribute>
                </xhtml:td>
              </if>
            </when>
          </choose>
          <apply-templates select="$step-set" mode="step-table">
            <with-param name="annotated" select="$annotated" />
            <with-param name="step-set" select="$step-set" />
            <with-param name="row-head" select="." />
          </apply-templates>
        </xhtml:tr>
      </for-each>
    </xhtml:table>
  </template>

  <template match="br:step" mode="step-table">
    <param name="annotated" />
    <param name="step-set" />
    <param name="row-head" />

    <variable name="refd-tmp">
      <call-template name="transitively-referenced-leaves">
        <with-param name="annotated" select="$annotated" />
      </call-template>
    </variable>
    <!-- XSLT result tree variables aren't node sets... Workaround: -->
    <variable name="refd" select="exsl:node-set($refd-tmp)/node()" />
    <variable name="first" select="$refd[1]" />

    <variable name="starts-at-this-row"
              select="$first/@id=$row-head/@id" />

    <if test="$starts-at-this-row">
      <xhtml:td>
        <variable name="e" select="." />
        <variable name="start-index">
          <for-each select="$step-set">
            <if test=".=$e"><number value="position()" /></if>
            </for-each>
        </variable>
        <variable name="ref-index">
          <for-each select="$step-set">
            <choose>
                <when test=".//br:ref[@r=$e/@id]">
                  <value-of select="position()" />
                </when>
            </choose>
          </for-each>
        </variable>
        <variable name="rowspan">
          <value-of select="count($refd)" />
        </variable>
        <variable name="colspan">
          <!-- Steps until refd (used) -->
          <choose>
            <when test="$ref-index != ''">
              <value-of select="$ref-index - $start-index" />
            </when>
            <otherwise><number value="1" /></otherwise>
          </choose>
        </variable>
        <call-template name="class-attr">
          <with-param name="extra-classes">
            <text>table-step</text>
            <if test="$rowspan > $colspan and
                      (2 * $rowspan) > string-length(@short)">
              <text> vertical-text</text>
            </if>
          </with-param>
        </call-template>
        <attribute name="rowspan">
          <value-of select="$rowspan" />
        </attribute>
        <attribute name="colspan">
          <value-of select="$colspan" />
        </attribute>
        <call-template name="link">
          <with-param name="text">
            <value-of select="@short" />
          </with-param>
        </call-template>
      </xhtml:td>
    </if>
  </template>

  <!-- A template mode to inline references to steps (for ease of
       processing - see `annotate-inlined`) -->
  <template match="node()"
            mode="inline-step-refs">
    <copy>
      <attribute name="id">
        <call-template name="get-id" />
      </attribute>
      <attribute name="generated-id">
        <value-of select="generate-id()" />
      </attribute>
      <apply-templates select="node()"
                       mode="inline-step-refs"/>
    </copy>
  </template>
  <template match="br:ref"
            mode="inline-step-refs">
    <!-- Resolve the reference -->
    <variable name="target" select="key('id', @r)" />
    <choose>
      <when test="$target/self::br:step">
        <apply-templates select="$target/self::node()"
                         mode="inline-step-refs"/>
      </when>
      <otherwise>
        <copy>
          <apply-templates select="node()"
                           mode="inline-step-refs"/>
        </copy>
      </otherwise>
    </choose>
  </template>

  <!-- For each step S in a tree from `inline-step-ref`,
       `annotate-inlined` adds an attribute "first-trefd-step-idx"
       that is the index of the first step transitively (and
       reflexively) referenced by S. This allows sorting the
       referenced steps according to the order in which their
       sub-components are started. -->
  <template mode="annotate-inlined"
            match="@*|node()">
    <copy>
      <apply-templates select="@*|node()" mode="annotate-inlined" />
    </copy>
  </template>
  <template mode="annotate-inlined"
            match="br:step">
    <variable name="transitively-referenced-step-indices">
      <for-each select="descendant-or-self::br:step">
        <!-- The 0-based index is the number of preceding step
             siblings before the original node in the document (and
             not in the inlined copy that we are traversing
             currently). -->
        <br:num>              <!-- Dummy element -->
          <number value="count($root//br:step[
                           generate-id()=current()/@generated-id
                         ]/preceding-sibling::br:step)" />
        </br:num>
      </for-each>
    </variable>
    <copy>
      <attribute name="first-trefd-step-idx">
        <value-of select="math:min(exsl:node-set(
                            $transitively-referenced-step-indices
                          )/br:num)" />
      </attribute>
      <apply-templates select="@*|node()" mode="annotate-inlined" />
    </copy>
  </template>

  <template name="copy-with-id">
    <copy>
      <attribute name="id">
        <call-template name="get-id" />
      </attribute>
      <attribute name="generated-id">
        <value-of select="generate-id()" />
      </attribute>
      <copy-of select="@*|text()|node()" />
    </copy>
  </template>

  <!-- Find the leaves of the transitive reference relation
       (ingredients or steps without inputs or recipes) -->
  <template name="transitively-referenced-leaves">
    <param name="annotated" />

    <if test="not(self::br:recipe)">
      <for-each select=".//br:ref|self::br:ref">
        <!-- Primary sort, annotated refs come first (refs to steps). -->
        <sort select="not($annotated//br:step[@id=current()/@r]/@first-trefd-step-idx)"/>
        <!-- Secondary sort, but the true reason for sorting: we want
             the steps to appear in the order that their sub-steps
             begin. In other words, we use the index of the first
             transitively referenced step. -->
        <sort select="$annotated//br:step[@id=current()/@r]
                      /@first-trefd-step-idx" data-type="number" />
        <for-each select="key('id', @r)">
          <call-template name="transitively-referenced-leaves">
            <with-param name="annotated" select="$annotated" />
          </call-template>
        </for-each>
      </for-each>
      <for-each select=".//br:ingredient">
        <call-template name="copy-with-id" />
      </for-each>
    </if>

    <for-each select="self::br:step[not(.//br:ingredient|.//br:ref)]|
                      self::br:result|
                      self::br:recipe">
      <call-template name="copy-with-id" />
    </for-each>
  </template>
</transform>
