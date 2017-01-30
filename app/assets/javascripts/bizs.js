// # Place all the behaviors and hooks related to the matching controller here.
// # All this logic will automatically be available in application.js.
// # You can use CoffeeScript in this file: http://coffeescript.org/
//
//


$(function(){


    $(".dim_selection").on('change', (function () {

        var myID = this.id;
        var id_to_change = '#' + 'biz_measures'+ myID.slice(-1);
        var from_id = '#'+myID + ' option:selected'

        var data = $(from_id).val();
        console.log(id_to_change);
        console.log(data);
        $('.active').removeClass('active');
        $(id_to_change).addClass('active');

        $.ajax({
            url: "/bizs/update_measures",
            type: "GET",
            datatype: 'script',
            data: {
                d_value: $(from_id).val()
            },
            success: function (data, status, xhr) {
                // console.log(data);
                change_select(data, id_to_change);
            },
            error: function (xhr, status, error) {
                console.log(xhr)
            }
        });

    }));

    $(".biz_factt").on('change',(function () {

        var myID = this.id;
        var id_to_change = '#biz_dimension0'//+ myID.slice(-1);
        // var from_id = '.'+myID + ' :selected'

        var data = $('#biz_fact :selected').val();
        // console.log(data);

        $('.active').removeClass('active');
        $(id_to_change).addClass('active');

        $.ajax({
            url: "/bizs/get_dimensions",
            type: "GET",
            datatype: 'script',
            data: {
                f_value: data
            },
            success: function (data, status, xhr) {
                // console.log(data);
                change_select(data, id_to_change);
            },
            error: function (xhr, status, error) {
                console.log(xhr)
            }
        });

    }));

    $(".add_more").on('click',(function (e) {
        e.preventDefault();
        var myID = this.id;
        var id_to_open = '#morediv' + (parseInt(myID.substring(5))+1); //'#more'+ parseInt(myID.slice(-1))+1;
        var id_to_change = '#' + 'biz_dimension'+ (parseInt(myID.substring(5))+1);
        // var from_id = '.'+myID + ' :selected'
        // collect data
        var data = [];
        var check_id = '#'+myID + ' option:selected'
        data.push($('#biz_fact :selected').val());
        for (var i=parseInt(myID.substring(5)); i >=0; i--){
            data.push($('#biz_dimension'+i).val());
        }
        // console.log(data);
        // console.log(myID.substring(5));
        // var data = $('#biz_fact :selected').val();
        console.log(id_to_change);
        $(id_to_open).show();
        $('.active').removeClass('active');
        $(id_to_change).addClass('active');

        $.ajax({
            url: "/bizs/update_dimensions",
            type: "GET",
            datatype: 'script',
            data: {
                a_value: data
            },
            success: function (data, status, xhr) {
                // console.log(data);
                change_select(data, id_to_change);
            },
            error: function (xhr, status, error) {
                console.log(xhr)
            }
        });

    }));

    // experimental
    $(".more_new").on('click',(function (e) {
        e.preventDefault();
        var myID = this.id;
        var id_to_open = '#morediv' + (parseInt(myID.substring(5))+1); //'#more'+ parseInt(myID.slice(-1))+1;
        var count = (parseInt(myID.substring(5))+1);
        var new_id = '#' + 'biz_dimension'+ (parseInt(myID.substring(5))+1);

        // $('#dimensions_measures').append( $('<div><tr><td><select id="<%= biz_dimension#{count} %>"><option>Select Dimension</option></select></td></tr></div>'));
        // var from_id = '.'+myID + ' :selected'
        // var div = document.getElementById('dimensions_measures');
        // var content = '<tr><td><select name="biz[dimensions_'+count+']" id="biz_dimension'+count+'" class="dim_selection"><option></option></select></td><td><select name="biz[measures_['+count+']][]" multiple="multiple" size="6" id="biz_measures'+count+'"><option></option></select></td><td><button name="button" type="submit" id="more_'+count+'" class="more_new">+Add</button></td></tr>'
        // div.innerHTML = div.innerHTML + content;
        // collect data
        var data = [];
        var check_id = '#'+myID + ' option:selected'
        data.push($('#biz_fact :selected').val());
        for (var i=parseInt(myID.substring(5)); i >=0; i--){
            data.push($('#biz_dimension'+i).val());
        }
        // console.log(data);
        // console.log(myID.substring(5));
        // var data = $('#biz_fact :selected').val();
        console.log(new_id);
        $(id_to_open).show();
        $('.active').removeClass('active');
        $(new_id).addClass('active');

        $.ajax({
            url: "new_factors",
            type: "GET",
            datatype: 'script',
            data: {
                a_value: data
            },
            success: function (data, status, xhr) {
                // console.log(data);
                change_select(data, new_id);
            },
            error: function (xhr, status, error) {
                console.log(xhr)
            }
        });

    }));
})

function change_select(data, id_to_change) {
    var json = jQuery.parseJSON(data);
    var options = [];
    json.each(function (key, index) {
        options.push({text: index, value:key});
    });
    $(id_to_change).replaceOptions(options);
}

$(function(){

})