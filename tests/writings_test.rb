# Run with the same Jekyll used by GitHub Pages: ruby tests/writings_test.rb
require 'jekyll'
require 'minitest/autorun'
require 'tmpdir'
require 'fileutils'

class WritingsTest < Minitest::Test
  ROOT = File.expand_path('..', __dir__)

  def setup
    @tmp = File.realpath(Dir.mktmpdir('mvn-writings-test'))
    @source = File.join(@tmp, 'source')
    @destination = File.join(@tmp, 'site')
    FileUtils.mkdir_p(@source)
    %w[_config.yml _layouts _includes writings index.html CNAME].each do |path|
      FileUtils.cp_r(File.join(ROOT, path), @source)
    end
    # Keep draft scenarios independent of the article's publication status.
    article = File.join(@source, 'writings/classical-poems-yt/index.md')
    File.write(article, File.read(article).sub('published: true', 'published: false'))
  end

  def teardown
    FileUtils.remove_entry(@tmp)
  end

  def build(unpublished: false, baseurl: '')
    config = Jekyll.configuration(
      'source' => @source, 'destination' => @destination,
      'unpublished' => unpublished, 'baseurl' => baseurl, 'quiet' => true,
      'safe' => true
    )
    Jekyll::Site.new(config).process
  end

  def output(path)
    File.read(File.join(@destination, path))
  end

  def publish_starter
    path = File.join(@source, 'writings/classical-poems-yt/index.md')
    File.write(path, File.read(path).sub('published: false', 'published: true'))
  end

  def add_article(slug, date, body = '')
    folder = File.join(@source, 'writings', slug)
    FileUtils.mkdir_p(folder)
    File.write(File.join(folder, 'index.md'), <<~ARTICLE)
      ---
      title: "#{slug}"
      description: "A test article & summary."
      date: #{date}
      published: true
      ---
      #{body}
    ARTICLE
  end

  def test_production_excludes_unpublished_starter_and_internal_files
    build
    assert_includes output('writings/index.html'), 'Articles are on their way.'
    refute_includes output('writings/index.html'), '/writings/classical-poems-yt/'
    refute File.exist?(File.join(@destination, 'writings/classical-poems-yt/index.html'))
    refute File.exist?(File.join(@destination, 'tests'))
    assert_includes output('index.html'), 'href="/writings/"'
    assert_equal 'mvn.me', output('CNAME').strip
  end

  def test_draft_preview_renders_metadata_cover_and_markdown
    build(unpublished: true)
    article = output('writings/classical-poems-yt/index.html')
    assert_includes article, '<h1>My Classical Poems YT Channel</h1>'
    assert_includes article, 'Draft · Not published'
    assert_includes article, '<time datetime="2026-10-11">October 11, 2026</time>'
    assert_includes article, 'https://mvn.me/writings/classical-poems-yt/'
    assert_includes article, 'src="/writings/classical-poems-yt/cover.png"'
    assert File.exist?(File.join(@destination, 'writings/classical-poems-yt/cover.png'))
    assert_includes article, '<h2 id="why-i-started-the-channel">'
    refute_includes article, 'VIDEO_ID'
    assert_equal 3, article.scan('<iframe ').size
    %w[j0p-oIVHwsk PHaAHlsnLDc vvms0uwQPM8].each do |video_id|
      assert_includes article, "https://www.youtube-nocookie.com/embed/#{video_id}"
    end
    assert_includes output('writings/index.html'), 'My Classical Poems YT Channel'
  end

  def test_new_articles_are_discovered_sorted_and_removed_on_rebuild
    publish_starter
    add_article('older', '2026-10-01')
    add_article('newer', '2026-10-12')
    build
    index = output('writings/index.html')
    links = index.scan(/<h2><a href="([^"]+)"/).flatten
    assert_equal ['/writings/newer/', '/writings/classical-poems-yt/', '/writings/older/'], links
    assert_includes index, 'A test article &amp; summary.'
    refute_includes index, ' · Draft'
    FileUtils.remove_entry(File.join(@source, 'writings/newer'))
    build
    refute_includes output('writings/index.html'), '/writings/newer/'
  end

  def test_multiple_images_and_both_video_types_render
    add_article('media', '2026-10-11', <<~BODY)
      ![First image](./first.png)

      ![Second image](./second.png)

      {% include youtube.html id="abc123def45" title="Poem & reading" caption="First reading" %}

      {% include youtube.html id="zyx987wvu65" title="Another reading" %}

      {% include video.html src="./reading.mp4" title="Local reading" poster="./first.png" captions="./reading.vtt" %}
    BODY
    build
    article = output('writings/media/index.html')
    assert_includes article, 'src="./first.png" alt="First image"'
    assert_includes article, 'src="./second.png" alt="Second image"'
    assert_equal 2, article.scan('<iframe ').size
    assert_includes article, 'https://www.youtube-nocookie.com/embed/abc123def45'
    assert_includes article, 'title="Poem &amp; reading"'
    assert_includes article, 'src="./reading.mp4" type="video/mp4"'
    assert_includes article, 'kind="captions" src="./reading.vtt"'
    assert_includes article, 'controls="" playsinline="" preload="metadata"'
    refute_includes article, '{%'
  end

  def test_site_links_respect_baseurl
    publish_starter
    build(baseurl: '/preview')
    assert_includes output('writings/index.html'), 'href="/preview/writings/classical-poems-yt/"'
    assert_includes output('writings/classical-poems-yt/index.html'), 'src="/preview/writings/classical-poems-yt/cover.png"'
  end

  def test_homepage_links_three_newest_published_articles_even_in_draft_preview
    add_article('oldest', '2026-10-01')
    add_article('third', '2026-10-10')
    add_article('second', '2026-10-12')
    add_article('newest', '2026-10-13')
    path = File.join(@source, 'writings/newest/index.md')
    File.write(path, File.read(path).sub('title: "newest"', 'title: "Newest & greatest"'))
    build(unpublished: true, baseurl: '/preview')
    homepage = output('index.html')
    links = homepage.scan(/<a href="(\/preview\/writings\/[^"\/]+\/)"/).flatten
    assert_equal ['/preview/writings/newest/', '/preview/writings/second/', '/preview/writings/third/'], links
    assert_includes homepage, 'Newest &amp; greatest'
    assert_includes homepage, '<time datetime="2026-10-13">October 13, 2026</time>'
    assert_includes homepage, 'href="/preview/writings/">View all writings'
    refute_includes homepage, '/writings/classical-poems-yt/'
    refute_includes homepage, '{%'
  end

  def test_homepage_handles_no_published_articles
    build
    homepage = output('index.html')
    assert_includes homepage, 'Recent writings'
    assert_includes homepage, 'Articles are on their way.'
    assert_includes homepage, 'View all writings'
    refute_includes homepage, '/writings/classical-poems-yt/'
  end
end
