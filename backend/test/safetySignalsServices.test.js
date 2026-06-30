const assert = require('assert/strict');
const {
  classifySignal,
  parseFeedItems,
} = require('../src/services/safetyNewsIngestionService');
const { parseGoogleMapsCoordinates } = require('../src/services/googlePlacesService');

describe('Safety signal services', () => {
  it('parses coordinates from Google Maps URLs', () => {
    const parsed = parseGoogleMapsCoordinates(
      'https://www.google.com/maps/@19.9975,73.7898,15z?entry=ttu',
    );

    assert.deepEqual(parsed, { lat: 19.9975, lng: 73.7898 });
  });

  it('classifies violent and property crime feeds', () => {
    assert.equal(classifySignal('Police report murder and attempt to murder case').category, 'murder');
    assert.equal(
      classifySignal('Chain snatching and theft reported near market').category,
      'chain_snatching',
    );
    assert.equal(
      classifySignal('Street light outage and isolated road').category,
      'infrastructure',
    );
  });

  it('parses RSS feed items', () => {
    const items = parseFeedItems(`
      <rss><channel>
        <item>
          <title>Police arrest theft suspect</title>
          <link>https://example.com/article-1</link>
          <description>Chain snatching reported near the station.</description>
          <pubDate>Tue, 30 Jun 2026 09:00:00 GMT</pubDate>
        </item>
      </channel></rss>
    `);

    assert.equal(items.length, 1);
    assert.equal(items[0].title, 'Police arrest theft suspect');
    assert.equal(items[0].sourceId, 'https://example.com/article-1');
  });
});
