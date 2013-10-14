$(function() {
  function generateURL() {
    var url = $('#url').attr('default');
    url += $('#server').val();
    url += '/';
    url += encodeURIComponent($('#channel').val());

    var query = [];

    if ($('#key').val())
      query.push('key=' + encodeURIComponent($('#key').val()));

    if (!$('#join').is(':checked'))
      query.push('nojoin');

    if ($('#part').is(':checked'))
      query.push('part');

    if ($('#notice').is(':checked'))
      query.push('notice');

    if (query.length)
      url += '?' + query.join('&');

    $('#url').val(url);
  }

  $('#server').change(generateURL);
  $('#channel').keyup(generateURL);
  $('#key').keyup(generateURL);
  $('#join').change(generateURL);
  $('#part').change(generateURL);
  $('#notice').change(generateURL);

  $('#url').focus(function() {
    $(this).one('mouseup', function() {
      return false; // Prevent deselect
    }).select();
  });

  generateURL();
});
