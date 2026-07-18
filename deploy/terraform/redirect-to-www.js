// Runs at viewer-request for every request to mootmaker.com, before any
// origin fetch happens, and unconditionally 301-redirects to the same
// path/query on www.mootmaker.com. See cloudfront.tf.
function handler(event) {
    var request = event.request;
    var qs = request.querystring;
    var qsKeys = Object.keys(qs);
    var qsString = '';

    if (qsKeys.length > 0) {
        var pairs = [];
        for (var i = 0; i < qsKeys.length; i++) {
            var key = qsKeys[i];
            var value = qs[key].value;
            pairs.push(value ? key + '=' + value : key);
        }
        qsString = '?' + pairs.join('&');
    }

    return {
        statusCode: 301,
        statusDescription: 'Moved Permanently',
        headers: {
            location: { value: 'https://www.mootmaker.com' + request.uri + qsString }
        }
    };
}
