
wlog = -> $ '<p>' .add-class 'info' .text it .append-to 'body'
werr = -> $ '<p>' .add-class 'error' .text it .append-to 'body'

export wlog, werr

