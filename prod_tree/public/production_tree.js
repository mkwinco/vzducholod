function romanize (num) {
    if (!+num)
        return 0;
    var digits = String(+num).split(""),
        key = ["","C","CC","CCC","CD","D","DC","DCC","DCCC","CM",
               "","X","XX","XXX","XL","L","LX","LXX","LXXX","XC",
               "","I","II","III","IV","V","VI","VII","VIII","IX"],
        roman = "",
        i = 3;
    while (i--)
        roman = (key[+digits.pop() + (i * 10)] || "") + roman;
    return Array(+digits.join("") + 1).join("M") + roman;
};


function refresh() {

	jQuery.ajax({
		async: true,
		url: 'production_tree.api',
	//	data: data,
		success: function(data,status){

			// variables tracking positioning of the activities on the svg plain
			//lines stores occupancy on the lines
			var lines = [0];
			var counter = [0];

			// Create separate line for each production level
			data.activities.forEach(function(v,i) {

				var aux = v.aux_production_level;

				//console.dir(v);
				if (typeof lines[aux] === 'undefined') {lines[aux]=0;};
				if (typeof counter[aux] === 'undefined') {counter[aux]=0;};

				lines[aux]++;
			});

			console.log(lines);

			// Production box size
			var pbw = 200;
			var pbh = 200;

			//Width and height
			var w = pbw*Math.max(...lines);
			var h = pbh*(lines.length);

			//object, storing item begining-end lines info
			var item_lines = {};

			console.dir([w,h]);
			var table = d3.select("body").append("svg").attr("width", w).attr("height", h);



			// create production cards
			var production_groups = table.selectAll("g")
				.data(data.activities)
				.enter()
				.append("g")
				.attr('id',function(d,i){return "prod_" + i})
				.append("rect")
				.attr('class', 'prod')
				.attr("x",function(d,i){counter[d.aux_production_level]++; return (counter[d.aux_production_level]-1)*pbw})
				.attr("y",function(d,i){return (d.aux_production_level)*pbh})
				.attr("width", pbw*0.9).attr("height", pbh*0.9)
				.attr("fill", "lightblue")
				.attr("stroke","black")
				.attr("stroke-width",2);

			//console.dir(production_groups);

			production_groups[0].forEach(function(v,i) {

				//console.log(i);
				//console.dir(v);


				// to simplify notation
				//console.dir(v.__data__);
				var a = v.__data__;
				console.dir(a);

				// select i-th group
				var gr = d3.select('#prod_'+i)

				// get the absolute coordinates of parent (rect) element
				var bbox = gr[0][0].getBBox();
				console.dir(bbox);

				//console.log(a.activity);
				var text = gr
					.append("text")
					.text(a.activity.toUpperCase())
					.attr("x",bbox.x+10).attr("y",bbox.y+13)
					.attr("font-family", "sans-serif")
					.attr("font-size", "14px")
					.attr("fill", "black");

				// item icon space
				var iis = 40; //(200*0.9/6 )

				//console.dir(a.inputs);
				//console.log(d3.keys(a.inputs));
				var k = d3.keys(a.inputs);
				//k = ["first", "second"];
				//console.log(k);
				//console.log(k[0]);


				var inputs_icon = gr.selectAll("rect.inputs")
					.data(k)
					.enter()
					.append("rect")
					.attr('class', function(d,j){

						if (typeof item_lines[d] === 'undefined') {item_lines[d]={"in":{},"out":{}}; };
						item_lines[d].in[a.aid]={"x":bbox.x + (j%6)*iis+5, "y":bbox.y + Math.floor(j/5)*iis+15};

						return "item_" + d

					})
					.attr("x",function(d,j){return item_lines[d].in[a.aid].x})
					.attr("y",function(d,j){return item_lines[d].in[a.aid].y})
					.attr("width", iis*0.9).attr("height", iis*0.9)
					.attr("fill", "black");

				var inputs_text = gr.selectAll("text.inputs")
					.data(k)
					.enter()
					.append("text")
					.text(function(d,i){return d;})
					.attr("x",function(d,j){return item_lines[d].in[a.aid].x+2;})
					.attr("y",function(d,j){return item_lines[d].in[a.aid].y+30})
					.attr("font-family", "sans-serif")
					.attr("font-size", "8px")
					.attr("fill", "white");

				var inputs_icon_count = gr.selectAll("text.inputs_count")
					.data(d3.values(a.inputs))
					.enter()
					.append("text")
					.text(function(d,i){return d + "";})
					// I know, it's ineffective - but this whole project is just auxiliary
					.attr("x",function(d,j){return bbox.x + (j%6)*iis+17;})
					.attr("y",function(d,j){return bbox.y + Math.floor(j/5)*iis+30})
					.attr("font-family", "sans-serif")
					.attr("font-size", "12px")
					.attr("fill", "white");

				var structure = gr.append("rect")
					.attr("class",'structure_' + a.structure)
					.attr("x",bbox.x + 5)
					.attr("y",function(d,j){return bbox.y + 55})
					.attr("width", pbw*0.4).attr("height", pbh*0.4)
					.attr("fill", "yellow")
					.attr("stroke", "orange")
					.attr("stroke-with", 15);

				gr.append("text")
					.text(a.structure.toUpperCase())
					.attr("x",bbox.x + 15)
					.attr("y",bbox.y + 95)
					.attr("font-family", "sans-serif")
					.attr("font-size", "12px")
					.attr("fill", "black");

				gr.append("text")
					.text(romanize(a.min_struct_level))
					.attr("x",bbox.x + 25)
					.attr("y",bbox.y + 115)
					.attr("font-family", "sans-serif")
					.attr("font-size", "12px")
					.attr("fill", "black");

				k = d3.keys(a.outputs);

				var outputs_icon = gr.selectAll("rect.outputs")
					.data(k)
					.enter()
					.append("rect")
					.attr('class', function(d,j){

						if (typeof item_lines[d] === 'undefined') {item_lines[d]={"in":{},"out":{}}; };
						item_lines[d].out[a.aid]={"x":bbox.x + (j%6)*iis+5, "y":bbox.y + Math.floor(j/5)*iis+140};

						return "item_" + d;})
					.attr("x",function(d,j){return item_lines[d].out[a.aid].x;})
					.attr("y",function(d,j){return item_lines[d].out[a.aid].y})
					.attr("width", iis*0.9).attr("height", iis*0.9)
					.attr("fill", "black");

				var outputs_text = gr.selectAll("text.outputs")
					.data(k)
					.enter()
					.append("text")
					.text(function(d,i){return d;})
					.attr("x",function(d,j){return item_lines[d].out[a.aid].x+2;})
					.attr("y",function(d,j){return item_lines[d].out[a.aid].y+30})
					.attr("font-family", "sans-serif")
					.attr("font-size", "8px")
					.attr("fill", "white");

				var outputs_icon_count = gr.selectAll("text.outputs_count")
					.data(d3.values(a.outputs))
					.enter()
					.append("text")
					.text(function(d,i){return d + "";})
					.attr("x",function(d,j){return bbox.x + (j%6)*iis+17;})
					.attr("y",function(d,j){return bbox.y + Math.floor(j/5)*iis+155})
					.attr("font-family", "sans-serif")
					.attr("font-size", "12px")
					.attr("fill", "white");


				var tools_icon = gr.selectAll("rect.tools")
					.data(d3.values(a.tools))
					.enter()
					.append("rect")
					.attr('class', function(d){return "tool_" + d})
					.attr("x",function(d,j){return bbox.x + 90;})
					.attr("y",function(d,j){return bbox.y + j*24+57})
					.attr("width", 30).attr("height", 20)
					.attr("fill", function(d,j){return d ? "red" : "blue"});

				var tools_text = gr.selectAll("text.tools")
					.data(d3.keys(a.tools))
					.enter()
					.append("text")
					.text(function(d,i){return d;})
					.attr("x",function(d,j){return bbox.x + 91;})
					.attr("y",function(d,j){return bbox.y + j*24+70})
					.attr("font-family", "sans-serif")
					.attr("font-size", "7px")
					.attr("fill", "white");

				gr.append("text")
					.text(a.stamina)
					.attr("x",bbox.x + 125)
					.attr("y",bbox.y + 100)
					.attr("font-family", "sans-serif")
					.attr("font-size", "24px")
					.attr("fill", "black");


			});

			//console.dir(production_groups);
			//console.dir(item_lines);
			for (var i in item_lines) {
				//console.dir(item_lines[i]);
				//console.log(i);

				for (var aut in item_lines[i].out) {
					//console.log("out");
					//console.dir(item_lines[i].out[aut]);

					for (var ain in item_lines[i].in) {

					//console.log("in");
					//console.dir(item_lines[i].in[ain]);

					// create connecting lines
					table.append("line")
						.attr("x1",item_lines[i].out[aut].x+15)
						.attr("y1",item_lines[i].out[aut].y+31)
						.attr("x2",item_lines[i].in[ain].x+15)
						.attr("y2",item_lines[i].in[ain].y+3)
						.attr("stroke", "white")
						.attr("stroke-width", "3");

					}
				}


			};

		}
	});
};
