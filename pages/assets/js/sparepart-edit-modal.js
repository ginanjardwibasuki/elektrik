$(document).ready(function() {
const edittextarea = document.getElementById('editkeywordInput');
  const edittagWrapper = document.getElementById('edittagWrapper');
  const editkeywordsvalue = document.getElementById('editinputankeyword');
  const editkeywords = [];

  function updateeditTextarea() {
	editkeywordsvalue.value = editkeywords.join(', ');
  }

  function createeditTag(label) {
    const edittag = document.createElement('span');
    edittag.className = 'tag';
    edittag.textContent = label;

    const removeeditBtn = document.createElement('button');
    removeeditBtn.className = 'remove';
    removeeditBtn.innerHTML = '&times;';
    removeeditBtn.onclick = function () {
      const editindex = editkeywords.indexOf(label);
      if (editindex !== -1) editkeywords.splice(editindex, 1);
      edittagWrapper.removeChild(edittag);
      updateeditTextarea();
    };

    edittag.appendChild(removeeditBtn);
    edittagWrapper.appendChild(edittag);
  }

	// Trigger ketika user mengetik koma
	edittextarea.addEventListener('input', function () {
	  const editvalue = edittextarea.value;
	  if (editvalue.includes(',')) {
		const editraw = editvalue.replace(',', '').trim();
		if (editraw && !editkeywords.includes(editraw)) {
		  editkeywords.push(editraw);
		  createeditTag(editraw);
		  updateeditTextarea();
		}
		edittextarea.value = '';
	  }
	});

	// Trigger ketika user menekan Enter
	edittextarea.addEventListener('keydown', function (e) {
	  if (e.key === 'Enter') {
		e.preventDefault(); // Hindari line break di edittextarea
		const editraw = edittextarea.value.trim();
		if (editraw && !editkeywords.includes(editraw)) {
		  editkeywords.push(editraw);
		  createeditTag(editraw);
		  updateeditTextarea();
		}
		edittextarea.value = '';
	  }
	});
	
	editModal.addEventListener('show.bs.modal', function () {
		const rawvalue = editkeywordsvalue.value || "";  // Ambil nilai dari input hidden

		  rawvalue.split(',').forEach(item => {
			const keyword = item.trim();
			if (keyword && !editkeywords.includes(keyword)) {
			  editkeywords.push(keyword);
			  createeditTag(keyword);
			}
		  });

		  updateeditTextarea();

	  });
	
	editModal.addEventListener('hidden.bs.modal', function () {
		editkeywords.length = 0;
		edittagWrapper.innerHTML = '';
		editkeywordsvalue.value = '';
	  });
	  
	
	});