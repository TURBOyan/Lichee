// SPDX-License-Identifier: LGPL-2.1-or-later
/*
 * This file is part of libgpiod.
 *
 * Copyright (C) 2017-2018 Bartosz Golaszewski <bartekgola@gmail.com>
 */

#include <functional>
#include <gpiod.hpp>
#include <map>
#include <system_error>
#include <utility>

namespace gpiod {

namespace {

::gpiod_chip* open_lookup(const ::std::string& device)
{
	return ::gpiod_chip_open_lookup(device.c_str());
}

::gpiod_chip* open_by_path(const ::std::string& device)
{
	return ::gpiod_chip_open(device.c_str());
}

::gpiod_chip* open_by_name(const ::std::string& device)
{
	return ::gpiod_chip_open_by_name(device.c_str());
}

::gpiod_chip* open_by_label(const ::std::string& device)
{
	return ::gpiod_chip_open_by_label(device.c_str());
}

::gpiod_chip* open_by_number(const ::std::string& device)
{
	return ::gpiod_chip_open_by_number(::std::stoul(device));
}

using open_func = ::std::function<::gpiod_chip* (const ::std::string&)>;

const ::std::map<int, open_func> open_funcs = {
	{ chip::OPEN_LOOKUP,	open_lookup,	},
	{ chip::OPEN_BY_PATH,	open_by_path,	},
	{ chip::OPEN_BY_NAME,	open_by_name,	},
	{ chip::OPEN_BY_LABEL,	open_by_label,	},
	{ chip::OPEN_BY_NUMBER,	open_by_number,	},
};

void chip_deleter(::gpiod_chip* chip)
{
	::gpiod_chip_close(chip);
}

} /* namespace */

chip::chip(const ::std::string& device, int how)
	: _m_chip()
{
	this->open(device, how);
}

chip::chip(::gpiod_chip* chip)
	: _m_chip(chip, chip_deleter)
{

}

void chip::open(const ::std::string& device, int how)
{
	auto func = open_funcs.at(how);

	::gpiod_chip *chip = func(device);
	if (!chip)
		throw ::std::system_error(errno, ::std::system_category(),
					  "cannot open GPIO device " + device);

	this->_m_chip.reset(chip, chip_deleter);
}

void chip::reset(void) noexcept
{
	this->_m_chip.reset();
}

::std::string chip::name(void) const
{
	this->throw_if_noref();

	return ::std::string(::gpiod_chip_name(this->_m_chip.get()));
}

::std::string chip::label(void) const
{
	this->throw_if_noref();

	return ::std::string(::gpiod_chip_label(this->_m_chip.get()));
}

unsigned int chip::num_lines(void) const
{
	this->throw_if_noref();

	return ::gpiod_chip_num_lines(this->_m_chip.get());
}

line chip::get_line(unsigned int offset) const
{
	this->throw_if_noref();

	if (offset >= this->num_lines())
		throw ::std::out_of_range("line offset greater than the number of lines");

	::gpiod_line* line_handle = ::gpiod_chip_get_line(this->_m_chip.get(), offset);
	if (!line_handle)
		throw ::std::system_error(errno, ::std::system_category(),
					  "error getting GPIO line from chip");

	return line(line_handle, *this);
}

line chip::find_line(const ::std::string& name) const
{
	this->throw_if_noref();

	::gpiod_line* handle = ::gpiod_chip_find_line(this->_m_chip.get(), name.c_str());
	if (!handle && errno != ENOENT)
		throw ::std::system_error(errno, ::std::system_category(),
					  "error looking up GPIO line by name");

	return handle ? line(handle, *this) : line();
}

line_bulk chip::get_lines(const ::std::vector<unsigned int>& offsets) const
{
	line_bulk lines;

	for (auto& it: offsets)
		lines.append(this->get_line(it));

	return lines;
}

line_bulk chip::get_all_lines(void) const
{
	line_bulk lines;

	for (unsigned int i = 0; i < this->num_lines(); i++)
		lines.append(this->get_line(i));

	return lines;
}

line_bulk chip::find_lines(const ::std::vector<::std::string>& names) const
{
	line_bulk lines;
	line line;

	for (auto& it: names) {
		line = this->find_line(it);
		if (!line) {
			lines.clear();
			return lines;
		}

		lines.append(line);
	}

	return lines;
}

bool chip::operator==(const chip& rhs) const noexcept
{
	return this->_m_chip.get() == rhs._m_chip.get();
}

bool chip::operator!=(const chip& rhs) const noexcept
{
	return this->_m_chip.get() != rhs._m_chip.get();
}

chip::operator bool(void) const noexcept
{
	return this->_m_chip.get() != nullptr;
}

bool chip::operator!(void) const noexcept
{
	return this->_m_chip.get() == nullptr;
}

void chip::throw_if_noref(void) const
{
	if (!this->_m_chip.get())
		throw ::std::logic_error("object not associated with an open GPIO chip");
}

} /* namespace gpiod */
